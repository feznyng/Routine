import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_service.dart';

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
      print('Failed to read refresh token from secure storage: $e');
      // Continue without the refresh token
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
          print('Restored session for user: ${response.user?.email}');
        }
      } catch (e) {
        print('Failed to restore session: $e');
        try {
          await _storage.delete(key: 'supabase_refresh_token');
        } catch (storageError) {
          print('Failed to delete refresh token: $storageError');
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
        try {
          await _storage.write(key: 'supabase_refresh_token', value: session.refreshToken);
        } catch (e) {
          print('Failed to write refresh token to secure storage: $e');
          // Continue despite storage error
        }
      } else {
        try {
          await _storage.delete(key: 'supabase_refresh_token');
        } catch (e) {
          print('Failed to delete refresh token from secure storage: $e');
          // Continue despite storage error
        }
      }
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          print('User signed in: ${session?.user.email}');
          break;
        case AuthChangeEvent.signedOut:
          print('User signed out');
          break;
        case AuthChangeEvent.userUpdated:
          print('User updated: ${session?.user.email}');
          break;
        case AuthChangeEvent.passwordRecovery:
          print('Password recovery requested');
          break;
        case AuthChangeEvent.tokenRefreshed:
          print('Token refreshed for user: ${session?.user.email}');
          break;
        default:
          print('Auth event: $event');
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
        SyncService().addJob(SyncJob(remote: false));
        SyncService().setupRealtimeSync();
      }

      return response.user != null;
    } on AuthException catch (e) {
      print('Sign in error: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        throw 'Incorrect email or password';
      } else if (e.message.contains('Email not confirmed')) {
        throw 'Please verify your email address';
      }
      throw 'Unable to sign in. Please try again later.';
    } catch (e) {
      print('Unexpected sign in error: $e');
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
      print('Sign up error: ${e.message}');
      if (e.message.contains('already registered')) {
        throw 'An account with this email already exists';
      } else if (e.message.contains('weak password')) {
        throw 'Please choose a stronger password';
      }
      throw 'Unable to create account. Please try again later.';
    } catch (e) {
      print('Unexpected sign up error: $e');
      throw 'Unable to create account. Please try again later.';
    }
  }

  Future<void> signOut() async {
    if (!_initialized) throw Exception('AuthService not initialized');
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw 'Unable to sign out. Please try again later.';
    }
  }
  
  // Method to handle app resume events
  void _setupResumeListener() {
    // This will be called from the app lifecycle state changes
  }
  
  // Method to notify that the app has resumed
  void notifyAppResumed() {
    _resumeStreamController.add(null);
    _refreshSessionIfNeeded();
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
          print('Token expired or about to expire, refreshing...');
          await _client.auth.refreshSession();
        }
      }
    } catch (e) {
      print('Error refreshing session: $e');
      // If refresh fails, try to recover by reading from storage
      try {
        final refreshToken = await _storage.read(key: 'supabase_refresh_token');
        if (refreshToken != null) {
          try {
            await _client.auth.refreshSession();
            print('Successfully refreshed session after error');
          } catch (refreshError) {
            print('Failed to refresh session after error: $refreshError');
          }
        }
      } catch (storageError) {
        print('Failed to read refresh token from storage: $storageError');
      }
    }
  }
  
  // Clean up resources
  void dispose() {
    _resumeStreamController.close();
  }
}
