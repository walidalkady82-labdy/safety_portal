import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_portal/core/themes.dart';

class ScreenLogin extends StatefulWidget {
  const ScreenLogin({super.key});

  @override
  State<ScreenLogin> createState() => _ScreenLoginState();
}

class _ScreenLoginState extends State<ScreenLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      if (_isRegistering) {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await cred.user?.sendEmailVerification();
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      String msg = "Authentication Failed.";
      if (e.toString().contains("user-not-found")) msg = "User not found.";
      if (e.toString().contains("wrong-password")) msg = "Incorrect password.";
      if (e.toString().contains("email-already-in-use")) msg = "Email already registered.";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.engineering, size: 60, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(_isRegistering ? "Create Account" : "Titan Maintenance", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                    Text(_isRegistering ? "Join the Portal" : "Industrial Database System", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController, 
                      decoration: const InputDecoration(labelText: "Work Email", prefixIcon: Icon(Icons.email)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController, 
                      decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)), 
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, 
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuth, 
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : Text(_isRegistering ? "Register" : "Sign In", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isRegistering = !_isRegistering), 
                      child: Text(_isRegistering ? "Already have an account? Login" : "No account? Register here"),
                    ),
                    const Divider(height: 32),
                    TextButton(
                      onPressed: () => FirebaseAuth.instance.signInAnonymously(), 
                      child: const Text("Continue as Guest (View Only)", style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
