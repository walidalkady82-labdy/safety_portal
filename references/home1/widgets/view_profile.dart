import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/presentation/auth/auth_wrapper.dart';

class ViewProfile extends StatelessWidget {
  const ViewProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(Icons.person, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            user?.email ?? "Guest User",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Safety Officer", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () async {
               await FirebaseAuth.instance.signOut();
               if(context.mounted) {
                 Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
               }
            },
            icon: const Icon(Icons.logout),
            label: const Text("Sign Out"),
          )
        ],
      ),
    );
  }
}