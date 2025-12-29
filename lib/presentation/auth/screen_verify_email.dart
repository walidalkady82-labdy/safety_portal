import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_portal/core/themes.dart';

class ScreenVerifyEmail extends StatefulWidget {
  const ScreenVerifyEmail({super.key});

  @override
  State<ScreenVerifyEmail> createState() => _ScreenVerifyEmailState();
}

class _ScreenVerifyEmailState extends State<ScreenVerifyEmail> {
  bool _isResending = false;

  Future<void> _checkVerification() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {});
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification email sent.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text("Verify Your Email", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                "We sent a link to ${user?.email}.\nPlease click it to activate your account.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkVerification,
                  child: const Text("I've Verified My Email", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isResending ? null : _resendEmail,
                child: Text(_isResending ? "Sending..." : "Resend Verification Email"),
              ),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text("Cancel and Log Out", style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
