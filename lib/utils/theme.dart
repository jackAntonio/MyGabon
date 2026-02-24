import 'package:flutter/material.dart';

import 'colors.dart';

/// Centralized theme definitions for the app with light and dark variants.
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        secondary: AppColors.secondary,
        surface: Colors.white,
        onSurface: AppColors.text,
      ),
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text),
        bodyLarge: const TextStyle(fontSize: 16, color: AppColors.text),
        bodyMedium: const TextStyle(fontSize: 14, color: AppColors.text),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        showUnselectedLabels: false,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.black,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
      ),
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkText),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkText),
        bodyLarge: const TextStyle(fontSize: 16, color: AppColors.darkText),
        bodyMedium: const TextStyle(fontSize: 14, color: AppColors.darkText),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        filled: true,
        fillColor: AppColors.darkSurface,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black54,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        showUnselectedLabels: false,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
