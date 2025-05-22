import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _passwordController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _authService = AuthService();
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final newEmail = _newEmailController.text.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(newEmail)) {
      setState(() {
        _errorText = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      await _authService.updateEmail(
        _passwordController.text,
        newEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated. Please confirm your new email.')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _newEmailController,
              decoration: const InputDecoration(
                labelText: 'New Email',
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
                labelText: 'Current Password',
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Updating...'),
                      ],
                    )
                  : const Text('Update Email'),
            ),
          ],
        ),
      ),
    );
  }
}
