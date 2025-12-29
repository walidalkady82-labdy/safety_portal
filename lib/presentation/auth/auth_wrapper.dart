import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_portal/presentation/home/screen_home.dart';
import 'package:safety_portal/presentation/auth/screen_login.dart';
import 'package:safety_portal/presentation/auth/screen_verify_email.dart';

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
        
        final user = snapshot.data;
        if (user == null) return const ScreenLogin();
        if (user.isAnonymous || user.emailVerified) return const ScreenHome();

        return const ScreenVerifyEmail();
      },
    );
  }
}
