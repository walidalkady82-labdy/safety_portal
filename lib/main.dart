import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/data/model/model_user_data.dart';
import 'package:safety_portal/data/service/service_ai.dart';
import 'package:safety_portal/presentation/auth/auth_wrapper.dart';
import 'firebase_options.dart';

List<ModelUserData> globalUsers = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ServiceAI().initAllModels();
  runApp(const MaintenancePortalApp());
}

  Map<String, dynamic> convertToMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List) {
      Map<String, dynamic> map = {};
      for (int i = 0; i < value.length; i++) {
        if (value[i] != null) map[i.toString()] = value[i];
      }
      return map;
    }
    return {};
  }

class MaintenancePortalApp extends StatelessWidget {
  const MaintenancePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Titan Maintenance Portal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.personal,
          surface: Colors.white,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardTheme: const CardThemeData(
          elevation: 2,
          shadowColor: Colors.black12,
          margin: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

