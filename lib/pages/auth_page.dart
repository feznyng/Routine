import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  final _authService = AuthService();
  String? _errorText;
  String? _bannerMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorText = null;
      _bannerMessage = null;
    });

    try {
      final success = _isRegistering
          ? await _authService.signUp(_emailController.text, _passwordController.text)
          : await _authService.signIn(_emailController.text, _passwordController.text);

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: _bannerMessage != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    _bannerMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              )
            : null,
        title: Text(_isRegistering ? 'Register' : 'Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _handleSubmit(),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _handleSubmit,
              child: Text(_isRegistering ? 'Register' : 'Sign In'),
            ),
            const SizedBox(height: 8),
            if (!_isRegistering) TextButton(
              onPressed: () async {
                final success = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (context) => const ForgotPasswordPage(),
                  ),
                );
                if (success == true && mounted) {
                  setState(() {
                    _bannerMessage = 'Password reset email sent. Please check your inbox.';
                  });
                }
              },
              child: const Text('Forgot Password?'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isRegistering = !_isRegistering;
                  _errorText = null;
                  _bannerMessage = null;
                });
              },
              child: Text(_isRegistering
                  ? 'Already have an account? Sign in'
                  : 'Need an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
