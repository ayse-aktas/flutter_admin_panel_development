import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_admin_panel_development/screens/admin/admin_dashboard.dart';
import 'package:flutter_admin_panel_development/screens/auth/login_screen.dart';
import 'package:flutter_admin_panel_development/screens/user/user_main_screen.dart';
import 'package:flutter_admin_panel_development/services/auth_service.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<String>(
            future: authService.getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnapshot.data ?? 'user';

              if (role == 'admin') {
                return const AdminDashboard();
              } else {
                return const UserMainScreen();
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
