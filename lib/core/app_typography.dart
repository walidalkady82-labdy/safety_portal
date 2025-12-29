import 'package:flutter/material.dart';

/// Defines the text styles for the application.
/// This class is used to ensure consistent typography across the app.
class AppTypography {
  static const TextTheme textTheme = TextTheme(
    // For large titles on screens
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    // For smaller screen titles or large section headers
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    // For section titles within cards or modals
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    // For list tile titles
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    // Default text style for body content
    bodyMedium: TextStyle(fontSize: 16),
    // For smaller body text or subtitles
    bodySmall: TextStyle(fontSize: 14),
    // For button labels
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    // For captions or very small text like timestamps
    labelSmall: TextStyle(fontSize: 12, color: Colors.grey),
  );
}