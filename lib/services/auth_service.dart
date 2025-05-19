import 'dart:async';
import 'package:Routine/setup.dart';
import 'package:Routine/util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_service.dart';
import 'package:sentry/sentry.dart';

// MARK:REMOVE
import 'package:Routine/services/notification_service.dart';


class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  late final SupabaseClient _client;
  bool _initialized = false;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  // Add a stream controller to handle app resume events
  final StreamController<void> _resumeStreamController = StreamController<void>.broadcast();
  Stream<void> get onResume => _resumeStreamController.stream;
  
  AuthService._internal();

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (url == null || anonKey == null) {
      throw Exception('Missing Supabase credentials. Please check your .env file.');
    }

    // Try to restore the refresh token with error handling
    String? refreshToken;
    try {
      refreshToken = await _storage.read(key: 'supabase_refresh_token');
    } catch (e) {
      logger.e('Failed to read refresh token from secure storage: $e');
    }
    
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
    
    _client = Supabase.instance.client;
    
    // If we have a stored refresh token, try to recover the session
    if (refreshToken != null) {
      try {
        final response = await _client.auth.refreshSession();
        if (response.session != null) {
          logger.i('Restored session for user: ${response.user?.email}');
          initNotifications();
        }
      } catch (e, st) {
        Util.report('Failed to refresh session', e, st);
        try {
          await _storage.delete(key: 'supabase_refresh_token');
        } catch (storageError) {
          logger.e('Failed to delete refresh token: $storageError');
          // Continue despite storage error
        }
      }
    }
    // Listen for auth state changes
    _client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      // Store or remove refresh token based on auth state
      if (session != null) {
        Sentry.configureScope(
          (scope) => scope.setUser(SentryUser(id: session.user.id)),
        );

        try {
          await _storage.write(key: 'supabase_refresh_token', value: session.refreshToken);
        } catch (e, st) {
          Util.report('Failed to write refresh token to secure storage', e, st);
          // Continue despite storage error
        }
      } else {
        Sentry.configureScope(
          (scope) => scope.setUser(SentryUser(id: null)),
        );

        try {
          await _storage.delete(key: 'supabase_refresh_token');
        } catch (e) {
          logger.e('Failed to delete refresh token from secure storage: $e');
          // Continue despite storage error
        }
      }
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          logger.i('User signed in: ${session?.user.email}');
          break;
        case AuthChangeEvent.signedOut:
          logger.i('User signed out');
          break;
        case AuthChangeEvent.userUpdated:
          logger.i('User updated: ${session?.user.email}');
          break;
        case AuthChangeEvent.passwordRecovery:
          logger.i('Password recovery requested');
          break;
        case AuthChangeEvent.tokenRefreshed:
          logger.i('Token refreshed for user: ${session?.user.email}');
          break;
        default:
          logger.i('Auth event: $event');
      }
    });
    
    // Add method to handle app resume events
    _setupResumeListener();
  }

  bool get isSignedIn => _initialized ? _client.auth.currentUser != null : false;
  String? get currentUser => _initialized ? _client.auth.currentUser?.email : null;
  SupabaseClient get client => _client;

  Future<bool> signIn(String email, String password) async {
    if (!_initialized) throw Exception('AuthService not initialized');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        SyncService().setupRealtimeSync();
        SyncService().addJob(SyncJob(remote: false));
        initNotifications();
      }

      return response.user != null;
    } on AuthException catch (e) {
      logger.e('Sign in error: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw 'Incorrect email or password';
      } else if (e.message.contains('Email not confirmed')) {
        throw 'Please verify your email address';
      }
      throw 'Unable to sign in. Please try again later.';
    } catch (e, st) {
      Util.report('Unexpected sign in failure', e, st);
      throw 'Unable to sign in. Please try again later.';
    }
  }

  Future<bool> signUp(String email, String password) async {
    if (!_initialized) throw Exception('AuthService not initialized');
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response.user != null;
    } on AuthException catch (e) {
      logger.e('Sign up error: ${e.message}');
      if (e.message.contains('already registered')) {
        throw 'An account with this email already exists';
      } else if (e.message.contains('weak password')) {
        throw 'Please choose a stronger password';
      }
      throw 'Unable to create account. Please try again later.';
    } catch (e, st) {
      Util.report('Unexpected sign up failure', e, st);
      throw 'Unable to create account. Please try again later.';
    }
  }

  Future<void> signOut() async {
    if (!_initialized) throw Exception('AuthService not initialized');
    try {
      await _client.auth.signOut();
    } catch (e, st) {
      Util.report('Unexpected sign out failure', e, st);
      throw 'Unable to sign out. Please try again later.';
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    if (!_initialized) throw Exception('AuthService not initialized');
    try {
      await _client.auth.resetPasswordForEmail(email, redirectTo: "${dotenv.env['SITE_URL']}/reset-password");
    } on AuthException catch (e) {
      logger.e('Password reset error: ${e.message}');
      if (e.message.contains('not found')) {
        return;
      }
      throw 'Unable to send password reset email. Please try again later.';
    } catch (e, st) {
      Util.report('Unexpected sign up failure', e, st);
      throw 'Unable to send password reset email. Please try again later.';
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    if (!_initialized) throw Exception('AuthService not initialized');
    if (!isSignedIn) throw Exception('User not signed in');
    
    try {
      // First verify the current password by attempting to sign in
      final email = currentUser;
      if (email == null) throw Exception('Current user email not found');
      
      await signIn(email, currentPassword);
      
      // If sign in succeeded, update the password
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      logger.e('Password update error: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw 'Current password is incorrect';
      }
      throw 'Unable to update password. Please try again later.';
    } catch (e, st) {
      Util.report('Unexpected password change failure', e, st);
      throw 'Unable to update password. Please try again later.';
    }
  }

  Future<void> updateEmail(String password, String newEmail) async {
    if (!_initialized) throw Exception('AuthService not initialized');
    if (!isSignedIn) throw Exception('User not signed in');
    
    try {
      // First verify the password by attempting to sign in
      final email = currentUser;
      if (email == null) throw Exception('Current user email not found');
      
      await signIn(email, password);
      
      // If sign in succeeded, update the email
      await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
    } on AuthException catch (e) {
      logger.e('Email update error: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw 'Password is incorrect';
      } else if (e.message.contains('already registered')) {
        throw 'This email is already in use';
      }
      throw 'Unable to update email. Please try again later.';
    } catch (e, st) {
      Util.report('Unexpected email change failure', e, st);
      throw 'Unable to update email. Please try again later.';
    }
  }
  
  // Method to handle app resume events
  void _setupResumeListener() {
    // This will be called from the app lifecycle state changes
  }
  
  // Method to notify that the app has resumed
  Future<void> notifyAppResumed() async {
    _resumeStreamController.add(null);
    await _refreshSessionIfNeeded();
  }

  void initNotifications() {
    // MARK:REMOVE
    NotificationService().init();
  }
  
  // Method to refresh the session if needed
  Future<void> _refreshSessionIfNeeded() async {
    if (!_initialized || _client.auth.currentUser == null) return;
    
    try {
      // Check if we need to refresh the token
      final session = _client.auth.currentSession;
      if (session != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expiresAt = session.expiresAt;
        
        // If token is expired or about to expire in the next 5 minutes, refresh it
        if (expiresAt != null && (expiresAt < now + 300)) {
          logger.i('Token expired or about to expire, refreshing...');
          await _client.auth.refreshSession();
        }
      }
    } catch (e, st) {
      Util.report('Error refreshing session', e, st);
    }
  }
  
  // Clean up resources
  void dispose() {
    _resumeStreamController.close();
  }
}
