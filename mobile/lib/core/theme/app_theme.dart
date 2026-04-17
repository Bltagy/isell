import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isell/core/config/app_config.dart';

/// App-wide design tokens
class AppColors {
  static const primary = Color(0xFFFF6B35);
  static const primaryLight = Color(0xFFFF8C42);
  static const primaryDark = Color(0xFFE55A25);
  static const background = Color(0xFFF8F8F8);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFB0B0B0);
  static const divider = Color(0xFFF0F0F0);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const star = Color(0xFFFFC107);
}

class AppTheme {
  AppTheme._();

  /// Returns the best font family for the given locale.
  /// Cairo for Arabic (beautiful, modern, great readability).
  /// Poppins for English/Latin.
  static String fontFamily(String locale) =>
      locale == 'ar' ? 'Cairo' : 'Poppins';

  static TextTheme _textTheme(String locale) {
    final tf = locale == 'ar'
        ? GoogleFonts.cairoTextTheme
        : GoogleFonts.poppinsTextTheme;
    return tf(const TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    ));
  }

  static ThemeData light(AppConfig config, {String locale = 'en'}) {
    final primary = config.primaryColor;
    final ff = fontFamily(locale);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: config.secondaryColor,
      tertiary: config.accentColor,
      brightness: Brightness.light,
      surface: AppColors.surface,
      background: AppColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: ff,
      textTheme: _textTheme(locale),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: ff,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ff),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ff),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: ff),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        selectedColor: primary,
        backgroundColor: const Color(0xFFF5F5F5),
        labelStyle: TextStyle(fontSize: 13, fontFamily: ff),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: ff),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontFamily: ff),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 0),
    );
  }

  static ThemeData dark(AppConfig config, {String locale = 'en'}) {
    final primary = config.primaryColor;
    final ff = fontFamily(locale);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E2E),
      background: const Color(0xFF12121A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF12121A),
      fontFamily: ff,
      textTheme: _textTheme(locale),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

