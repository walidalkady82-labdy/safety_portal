import 'package:flutter/material.dart';
import 'package:safety_portal/core/themes.dart';

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
    // Header style for section titles (e.g., "Analytics", "New Report")
  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  // Label style for form fields and small section headers
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    letterSpacing: 0.2,
  );

  // Body text for general content
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: AppColors.textDark,
    height: 1.5,
  );

  // Small caption text
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );
}