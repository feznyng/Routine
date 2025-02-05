import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  late final SupabaseClient _client;
  bool _initialized = false;
  
  AuthService._internal();

  Future<void> initialize() async {
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
    );
    _client = Supabase.instance.client;
    
    // Listen for auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
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
        default:
          print('Auth event: $event');
      }
    });
  }

  bool get isSignedIn => _initialized ? _client.auth.currentUser != null : false;
  String? get currentUser => _initialized ? _client.auth.currentUser?.email : null;

  Future<bool> signIn(String email, String password) async {
    if (!_initialized) throw Exception('AuthService not initialized');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
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
}
