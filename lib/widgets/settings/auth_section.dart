import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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
        child: ListTile(
          leading: const Icon(Icons.person),
          title: Text('Signed in as ${authService.currentUser}'),
          trailing: TextButton(
            onPressed: () async {
              await authService.signOut();
              // We don't need to call setState here as the parent widget will handle it
            },
            child: const Text('Sign Out'),
          ),
        ),
      );
    }
  }
}
