class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isSignedIn = false;
  String? _currentUser;

  bool get isSignedIn => _isSignedIn;
  String? get currentUser => _currentUser;

  Future<bool> signIn(String email, String password) async {
    // Dummy implementation
    await Future.delayed(const Duration(seconds: 1));
    _isSignedIn = true;
    _currentUser = email;
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    // Dummy implementation
    await Future.delayed(const Duration(seconds: 1));
    _isSignedIn = true;
    _currentUser = email;
    return true;
  }

  Future<void> signOut() async {
    // Dummy implementation
    await Future.delayed(const Duration(milliseconds: 500));
    _isSignedIn = false;
    _currentUser = null;
  }
}
