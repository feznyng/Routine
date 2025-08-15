import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isLoading = false;
  bool _isResendingVerification = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isRegistering) {
      // Open waitlist signup form instead of registering
      await _openWaitlistForm();
      return;
    }

    setState(() {
      _errorText = null;
      _bannerMessage = null;
      _isLoading = true;
    });

    try {
      // Handle sign in
      final success = await _authService.signIn(_emailController.text, _passwordController.text);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorText = e.toString();
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWaitlistForm() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final uri = Uri.parse('https://ajan2.typeform.com/to/yeUrh6hI');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _errorText = 'Could not open signup form. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Error opening signup form: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: Text(_isRegistering ? 'Join Beta Waitlist' : 'Sign In'),
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
              if (_errorText == 'Please verify your email address') ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isResendingVerification ? null : () async {
                    setState(() {
                      _isResendingVerification = true;
                    });
                    try {
                      await _authService.resendVerificationEmail(_emailController.text);
                      if (mounted) {
                        setState(() {
                          _bannerMessage = 'Verification email sent. Please check your inbox.';
                          _errorText = null;
                          _isResendingVerification = false;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _errorText = e.toString();
                          _isResendingVerification = false;
                        });
                      }
                    }
                  },
                  child: _isResendingVerification
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Sending...'),
                        ],
                      )
                    : const Text('Resend verification email'),
                ),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 12),
                      Text('Loading...'),
                    ],
                  )
                : Text(_isRegistering ? 'Join Beta Waitlist' : 'Sign In'),
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
                if (_isRegistering) {
                  setState(() {
                    _isRegistering = false;
                    _errorText = null;
                    _bannerMessage = null;
                  });
                } else {
                  _openWaitlistForm();
                }
              },
              child: Text(_isRegistering
                  ? 'Already have an account? Sign in'
                  : 'Need an account? Sign up for one.'),
            ),
          ],
        ),
      ),
    );
  }
}
