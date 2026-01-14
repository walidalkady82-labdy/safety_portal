import 'package:flutter/material.dart';
import 'app_typography.dart';



class AppColors {
  static const primary = Color(0xFF6750A4);
  static const Color secondary = Color(0xFFFFC107);

  static const personal = Color(0xFF00796B);
  static const surface = Color(0xFFF6F8FA);
  static const background = Color(0xFFF4F7F6);
  static const onSurface = Color(0xFF1C1B1F);
  static const danger = Color(0xFFdc3545);
  static const warning = Color(0xFFffc107);
  static const info = Color(0xFF0dcaf0);
  static const purple = Color(0xFF6f42c1);
  static const darkBlue = Color(0xFF0d6efd);

  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textLight = Color(0xFF636E72);

  static const Color emerald = Color(0xFF50C878);
  static const Color emeraldShade50 = Color(0x50C878FF);
  static const Color emeraldShade800 = Color(0x008000FF);
}

class AppThemes {
  // A subtle shadow used for cards and containers to give depth
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x1A000000), // Black with low opacity
    blurRadius: 10,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

// The single light theme for the entire application, now based on the "Sunset Orange" design.
static final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFFFF7043), // Deep Orange
  fontFamily: 'Cairo-Regular',
  fontFamilyFallback: const ['NotoSansArabic', 'Cairo'],
  //scaffoldBackgroundColor: const Color(0xFFFFF3E0), // A very light orange
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.orange,
    brightness: Brightness.light,
  ).copyWith(
    secondary: const Color(0xFF81D4FA), // Light Blue accent
    //background: const Color(0xFFFFF3E0),
    surface: Colors.white,
    error: Colors.red.shade700,
  ),
  useMaterial3: true,
  textTheme: AppTypography.textTheme,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFF7043),
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF7043),
      foregroundColor: Colors.white,
      textStyle: AppTypography.textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFFF7043),
      side: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
      textStyle: AppTypography.textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFFF7043),
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade200,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  ),
);

/// The single dark theme for the entire application.
static final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFFF7043), // Keep the brand orange
  fontFamily: 'Cairo-Regular',
  fontFamilyFallback: const ['NotoSansArabic', 'Cairo'],
  scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark background
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.orange,
    brightness: Brightness.dark,
  ).copyWith(
    secondary: const Color(0xFF81D4FA), // Light Blue accent
    //background: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E), // Slightly lighter for cards/surfaces
    error: Colors.red.shade400,
  ),
  useMaterial3: true,
  textTheme: AppTypography.textTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E), // Dark surface color for app bar
    iconTheme: IconThemeData(color: Color(0xFFFF7043)), // Orange icons
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF7043),
      foregroundColor: Colors.white,
      textStyle: AppTypography.textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFFF7043),
      side: const BorderSide(color: Color(0xFFFF7043), width: 2),
      textStyle: AppTypography.textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFFF7043),
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade800,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  ),
);

}