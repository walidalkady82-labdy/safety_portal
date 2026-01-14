import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode,defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:safety_portal/core/themes.dart';
import 'package:safety_portal/locator.dart';
import 'package:safety_portal/presentation/auth/auth_cubit.dart';
import 'package:safety_portal/presentation/home/cubit_analytics.dart';
import 'package:safety_portal/core/local_manager.dart';
import 'package:safety_portal/presentation/home/cubit_report.dart';
import 'firebase_options.dart';
import 'presentation/home/cubit_home.dart';
import 'presentation/splash/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  final log = Logger("main");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // --- CONNECT TO EMULATORS ---
  // We only want to use emulators during development (debug mode)
  if (kDebugMode) {
    // 1. Determine the Host IP
    // Android Emulators need '10.0.2.2' to see your computer's localhost.
    // iOS and Web can use 'localhost'.
    String host = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

    log.info("Connecting to Firebase Emulators on $host...");

    try {
      // Connect Authentication (Port 9099)
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      
      // Connect Realtime Database (Port 9000)
      // Note: Ensure the databaseURL matches your project
      //FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
      
      // Connect Storage (Port 9199)
      //await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      
      log.info("✅ Successfully redirected to Local Emulators");
    } catch (e) {
      log.severe("❌ Error connecting to emulators: $e");
    }
  }
    // 3. MANDATORY AUTH (Rule 3)
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInAnonymously();
      log.info("Auth: Signed in anonymously");
    }
  } catch (e) {
    log.severe("Auth Error: $e");
  }
  await LocaleManager.instance.loadTranslations();
  await setupLocator();
  await sl.allReady();
  runApp(MaintenancePortalApp());
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
    return MultiBlocProvider(
        providers: [
        BlocProvider(create: (_) => AuthCubit()),
        // DataCubit now uses 'sl<AtrService>()' internally
        BlocProvider(create: (_) => HomeCubit()..init()), 
        // ReportCubit uses 'sl<ServiceAI>()'
        BlocProvider(create: (_) => ReportCubit()),
        // ForecastCubit uses 'sl<ServiceAI>()'
        BlocProvider(create: (_) => CubitAnalytics()..loadForecast()),
      ],
      child: ValueListenableBuilder(
        valueListenable: LocaleManager.instance,
        builder: (context, lang, child) {
          return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Titan Safety Portal'.t(),
                theme: ThemeData(
                  useMaterial3: true,
                  fontFamily: lang == 'ar' ? 'Cairo' : 'Inter',
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color.fromARGB(255, 105, 107, 112),
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
                localizationsDelegates: const [
                  // Built-in Flutter delegates for basic widgets
                  DefaultMaterialLocalizations.delegate,
                  DefaultWidgetsLocalizations.delegate,
                  DefaultCupertinoLocalizations.delegate,
                ],
                home: const MinimalSplashScreen(),
              );
        }
      ),
    );
  }
}
