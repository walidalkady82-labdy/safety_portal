import 'package:flutter/material.dart';

import '../auth/auth_wrapper.dart';

class MinimalSplashScreen extends StatefulWidget {
  const MinimalSplashScreen({super.key});

  @override
  _MinimalSplashScreenState createState() => _MinimalSplashScreenState();
}

class _MinimalSplashScreenState extends State<MinimalSplashScreen> {
  bool visibleLoading = false;
  @override
  void initState() {
    super.initState();
    // Move to next screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(seconds: 2),
          curve: Curves.elasticOut,
          builder: (context, double value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlutterLogo(size: 100),
              SizedBox(height: 20),
              Column(
                children: [
                  Text(
                    "SAFETY PORTAL",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Visibility(
                    visible: visibleLoading ,
                    child: Text("Loading..." , style: TextStyle(
                      color: Colors.white,))
                    )
                ],
              ),
            ],
          ),
          onEnd: () => {
                  setState(() {
                    visibleLoading = true;
                  })       
          },
        ),
      ),
    );
  }
}