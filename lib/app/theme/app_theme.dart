import 'package:flutter/material.dart';

class AppTheme {
  static const Color scaffoldBackground = Color(0xFF000000);
  static const Color cardSurface = Color(0xFF16181C);
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFF71767B);
  static const Color accentBlue = Color(0xFF1D9BF0);
  static const Color likeRed = Color(0xFFF91880);
  static const Color retweetGreen = Color(0xFF00BA7C);
  static const Color borderColor = Color(0xFF2F3336);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        onPrimary: Colors.white,
        secondary: secondaryText,
        onSecondary: Colors.white,
        surface: cardSurface,
        onSurface: primaryText,
        error: likeRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: primaryText),
      ),
      cardTheme: const CardTheme(
        color: cardSurface,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 0.5,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: secondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: primaryText),
        bodyMedium: TextStyle(color: primaryText),
        bodySmall: TextStyle(color: secondaryText),
        labelLarge: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: secondaryText),
        labelSmall: TextStyle(color: secondaryText),
      ),
      iconTheme: const IconThemeData(color: primaryText),
      primaryIconTheme: const IconThemeData(color: primaryText),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: scaffoldBackground,
        selectedItemColor: primaryText,
        unselectedItemColor: secondaryText,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 0),
        unselectedLabelStyle: TextStyle(fontSize: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: cardSurface,
        labelStyle: TextStyle(color: primaryText),
        side: BorderSide(color: borderColor),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardSurface,
        contentTextStyle: const TextStyle(color: primaryText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}