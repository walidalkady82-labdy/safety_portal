import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_portal/presentation/auth/screen_login.dart';
import 'package:safety_portal/presentation/auth/screen_verify_email.dart';
import 'package:safety_portal/presentation/home/screen_spredict.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
                
        // Simple check: if we have a user or if we are in a dev environment without auth enforcement
        if (snapshot.hasData || FirebaseAuth.instance.currentUser != null) {
          return const MainNavigationScreen();
        }
        // Fallback for demo if no Firebase Auth configured
        if (FirebaseAuth.instance.app.options.apiKey.isEmpty) {
           return const MainNavigationScreen();
        }
        final user = snapshot.data;
        if (user == null) return const ScreenLogin();
        if (user.isAnonymous || user.emailVerified) return const MainNavigationScreen();

        return const ScreenVerifyEmail();
      },
    );
  }
}
