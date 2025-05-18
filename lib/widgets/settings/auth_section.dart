import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../pages/account_settings_page.dart';

class AuthSection extends StatelessWidget {
  final VoidCallback onSignInTap;
  
  const AuthSection({
    super.key,
    required this.onSignInTap,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    if (!authService.isSignedIn) {
      return Card(
        child: InkWell(
          onTap: onSignInTap,
          child: const ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Sign In or Create Account'),
            subtitle: Text('Sync your routines across devices'),
          ),
        ),
      );
    } else {
      return Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AccountSettingsPage(),
              ),
            );
          },
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text('Signed in as ${authService.currentUser}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      );
    }
  }
}
