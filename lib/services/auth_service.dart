import 'dart:async';
import 'package:Routine/models/device.dart';
import 'package:Routine/setup.dart';
import 'package:Routine/util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock)
  );
  
  AuthService._internal();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (url == null || anonKey == null) {
      throw Exception('Missing Supabase credentials. Please check your .env file.');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false
      ),
    );
    
    _client = Supabase.instance.client;
    
    // Try to restore the refresh token with error handling
    String? refreshToken;
    try {
      refreshToken = await _storage.read(key: 'supabase_refresh_token');
    } catch (e) {
      logger.e('Failed to read refresh token from secure storage: $e');
    }
    
    if (refreshToken != null) {
      try {
        final response = await _client.auth.refreshSession();
        if (response.session != null) {
          logger.i('Restored session for user: ${response.user?.email}');
          initNotifications();
        }
      } catch (e) {
        logger.w('Failed to refresh session $e');
        try {
          await _storage.delete(key: 'supabase_refresh_token');
        } catch (storageError) {
          logger.e('Failed to delete refresh token: $storageError');
        }
      }
    }

    // Listen for auth state changes
    _client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      final prefs = await SharedPreferences.getInstance();
      
      // Store or remove refresh token based on auth state
      if (session != null) {
        // Update signed_in flag
        await prefs.setBool('signed_in', true);
        Sentry.configureScope(
          (scope) => scope.setUser(SentryUser(id: session.user.id)),
        );

        try {
          await _storage.write(key: 'supabase_refresh_token', value: session.refreshToken);
        } catch (e, st) {
          Util.report('Failed to write refresh token to secure storage', e, st);
        } 
      } else {
        final currDevice = await Device.getCurrent();

        Sentry.configureScope(
          (scope) => scope.setUser(SentryUser(id: currDevice.id)),
        );

        try {
          await _storage.delete(key: 'supabase_refresh_token');
        } catch (e) {
          logger.e('Failed to delete refresh token from secure storage: $e');
        }
      }
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          logger.i('User signed in: ${session?.user.email}');
          break;
        case AuthChangeEvent.signedOut:
          logger.i('User signed out');
          if (prefs.getBool('signed_in') ?? false) {
            await prefs.setBool('signed_in', false);
          }
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
  }

  bool get isSignedIn => _initialized ? _client.auth.currentUser != null : false;
  Future<bool?> get wasSignedOut async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('signed_in');
  }

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
      logger.w('Sign in error: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw 'Incorrect email or password';
      } else if (e.message.contains('missing email or phone')) {
        throw 'Please enter your email address';
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

      logger.i("sign up successful ${response.user}");

      final user = response.user;

      if (user == null) {
        return false;
      }

      logger.i("identities: ${user.identities}");

      return true;
    } on AuthException catch (e) {
      logger.w('Sign up error: ${e.message}');
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
      await clearSignedInFlag();
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
      logger.w('Password reset error: ${e.message}');
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
      final email = currentUser;
      if (email == null) throw Exception('Current user email not found');
      
      await signIn(email, currentPassword);
      
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      logger.w('Password update error: ${e.message}');
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
      final email = currentUser;
      if (email == null) throw Exception('Current user email not found');
            
      await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      await signOut();
    } on AuthException catch (e) {
      logger.w('Email update error: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw 'Password is incorrect';
      } else if (e.message.contains('already registered')) {
        throw 'This email is already in use';
      }
      throw 'Unable to update email. Please try again later.';
    } catch (e, st) {
      if (e.toString().contains('Incorrect email or password')) {
        throw 'Incorrect email or password';
      }

      Util.report('Unexpected email change failure', e, st);
      throw 'Unable to update email. Please try again later.';
    }
  }

  void initNotifications() {
    // MARK:REMOVE
    NotificationService().init();
  }
  
  Future<void> refreshSessionIfNeeded() async {
    if (!_initialized || _client.auth.currentUser == null) return;
    
    if (isSignedIn) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('signed_in', true);
    }
    
    try {
      final session = _client.auth.currentSession;
      if (session != null) {        
        await _client.auth.refreshSession();
      }
    } catch (e, st) {
      Util.report('Error refreshing session', e, st);
    }
  }

  Future<bool> deleteAccount() async {
    if (!_initialized) throw Exception('AuthService not initialized');
    if (!isSignedIn) throw Exception('User not signed in');
    
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw Exception('No active session found');
      
      final response = await _client.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      
      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        final message = response.data['message'] ?? 'Failed to delete account';
        logger.e('Account deletion error: $error - $message');
        throw 'Failed to delete account: $message';
      }
      
      logger.i('Account successfully deleted');
      
      // Sign out the user after successful account deletion
      await clearSignedInFlag();
      await _client.auth.signOut();

      return true;
    } catch (e, st) {
      Util.report('Unexpected account deletion failure', e, st);
    }

    return false;
  }
  
  Future<void> clearSignedInFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('signed_in');
  }
}
