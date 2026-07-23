import 'package:flutter/material.dart';

/// Color Palette for Tupi House - Premium Decor E-commerce
/// Based on: Warm Scandinavian minimalism, Curated decor boutique, Editorial commerce
/// Updated for 2026 e-commerce trends - Light, soft, clean, feminine but not childish
class AppColors {
  // Background - Warm Off-White with Soft Pink Tint
  static const Color background = Color(0xFFFFFAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoftPink = Color(0xFFFFF1F5);
  static const Color surfaceVariant = Color(0xFFF8F8F8);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Light Blush Background
  static const Color lightBlush = Color(0xFFFFF8FA);
  static const Color warmWhite = Color(0xFFFFFCFB);
  static const Color lightCream = Color(0xFFF8F2ED);

  // Primary - Rose Pink (Keep original brand color - main CTA)
  static const Color primaryPink = Color(0xFFD8658A);
  static const Color primaryPinkLight = Color(0xFFFFD9E5);
  static const Color primaryPinkDark = Color(0xFFB94E70);
  // Backward compatibility aliases
  static const Color softPink = Color(0xFFFFF1F5);
  static const Color pastelPink = Color(0xFFFFD9E5);
  static const Color pastelPinkDark = Color(0xFFD8658A);
  // Sale red pink
  static const Color saleRedPink = Color(0xFFE75279);

  // Secondary - Sage Green (sustainability, in-stock, secondary action)
  static const Color sageGreen = Color(0xFFA8B89A);
  static const Color sageGreenLight = Color(0xFFE4F0E4);
  static const Color sageGreenDark = Color(0xFF62745B);
  static const Color deepSage = Color(0xFF62745B);
  // Backward compatibility aliases
  static const Color softGreen = Color(0xFFE4F0E4);
  static const Color pastelGreen = Color(0xFFB8D4B0);
  static const Color pastelGreenDark = Color(0xFF4A6B4F);

  // Accent - Wood Brown (brand accent, subheadings, decor collection)
  static const Color woodBrown = Color(0xFF7A5848);
  static const Color woodBrownLight = Color(0xFFF1E6DF);
  static const Color woodBrownDark = Color(0xFF6B4D3A);
  // Backward compatibility aliases
  static const Color woodBrownAlt = Color(0xFFB8956C);
  static const Color woodBrownLightAlt = Color(0xFFD4B896);

  // Text Colors - Warm, readable
  static const Color textPrimary = Color(0xFF2F2A2B);
  static const Color textSecondary = Color(0xFF777171);
  static const Color muted = Color(0xFF9E9E9E);
  static const Color mutedLight = Color(0xFFBDBDBD);
  // Backward compatibility aliases
  static const Color ink = Color(0xFF2F2A2B);
  static const Color inkLight = Color(0xFF5A5A5A);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE8A94D);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorLight = Color(0xFFFFEBEE);

  // Border & Divider - Soft warm tones
  static const Color outlineSoft = Color(0xFFEEDFE4);
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);

  // Overlay
  static const Color overlay = Color(0x1A000000);

  // Backward-compatible aliases used by older files.
  static const Color tulipPink = primaryPinkDark;
  static const Color tulipPinkDark = primaryPinkDark;
  static const Color leafGreen = pastelGreenDark;
  static const Color leafGreenDark = pastelGreenDark;
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(useMaterial3: true, fontFamily: 'Poppins');
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPink,
        brightness: Brightness.light,
        primary: AppColors.primaryPink,
        onPrimary: Colors.white,
        secondary: AppColors.sageGreen,
        onSecondary: Colors.white,
        tertiary: AppColors.woodBrown,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: 'Poppins',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sageGreen,
          side: const BorderSide(color: AppColors.sageGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primaryPink, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.sageGreen,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryPinkLight,
        disabledColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryPink,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.outlineSoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outlineSoft, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static ThemeData get adminTheme {
    final base = ThemeData(useMaterial3: true, fontFamily: 'Poppins');
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPink,
        brightness: Brightness.light,
        primary: AppColors.primaryPink,
        secondary: AppColors.sageGreen,
        tertiary: AppColors.woodBrown,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: 'Poppins',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryPink,
            width: 1.6,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outlineSoft),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.softPink,
        side: const BorderSide(color: AppColors.outlineSoft),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
