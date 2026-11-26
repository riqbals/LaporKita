import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Konfigurasi tema global LaporKita menggunakan Material 3.
/// Mengunci font, warna, bentuk tombol, input, dan AppBar agar konsisten.
abstract final class AppTheme {
  static const double _inputRadius = 12;
  static const double _buttonHeight = 50;

  static ThemeData get lightTheme {
    final regularFamily = GoogleFonts.plusJakartaSans().fontFamily;
    final semiBoldFamily =
        GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600).fontFamily;
    final boldFamily =
        GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700).fontFamily;

    final baseTextTheme = ThemeData.light().textTheme.apply(
          fontFamily: regularFamily,
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primarySoft,
      onSecondary: AppColors.primaryDark,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: regularFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontFamily: boldFamily,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 26,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontFamily: boldFamily,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontFamily: semiBoldFamily,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontFamily: regularFamily,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontFamily: regularFamily,
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontFamily: semiBoldFamily,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontFamily: boldFamily,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 19,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        border: _outlineBorder(AppColors.border),
        enabledBorder: _outlineBorder(AppColors.border),
        focusedBorder: _outlineBorder(AppColors.primary, width: 1.5),
        errorBorder: _outlineBorder(AppColors.error),
        focusedErrorBorder: _outlineBorder(AppColors.error, width: 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primarySoft,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(double.infinity, _buttonHeight),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: baseTextTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_inputRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
