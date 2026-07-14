import 'package:flutter/material.dart';

class AppColors {
  static const Color pastelPink = Color(0xFFF7B6C8);
  static const Color pastelPinkDark = Color(0xFFD96C8F);
  static const Color pastelGreen = Color(0xFFB9D8B4);
  static const Color pastelGreenDark = Color(0xFF5F8D68);
  static const Color ink = Color(0xFF26322B);
  static const Color muted = Color(0xFF6C756F);
  static const Color background = Color(0xFFFFFAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color softPink = Color(0xFFFFEEF3);
  static const Color softGreen = Color(0xFFEFF8EC);

  // Backward-compatible aliases used by older files.
  static const Color tulipPink = pastelPinkDark;
  static const Color tulipPinkDark = pastelPinkDark;
  static const Color leafGreen = pastelGreenDark;
  static const Color leafGreenDark = pastelGreenDark;
  static const Color cardBackground = surface;
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(useMaterial3: true, fontFamily: 'Roboto');
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pastelPink,
        primary: AppColors.pastelPinkDark,
        secondary: AppColors.pastelGreenDark,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pastelPinkDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pastelGreenDark,
          side: const BorderSide(color: AppColors.pastelGreen),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.pastelPinkDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.pastelGreenDark,
        suffixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8E2E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8E2E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.pastelPinkDark, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.pastelGreenDark,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.softGreen,
        labelStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Color(0xFFE7ECE3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFF0E8EB)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
