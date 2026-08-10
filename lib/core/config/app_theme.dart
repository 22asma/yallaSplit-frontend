import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const base = Color(0xFF0C0C18);       // App background
  static const surface = Color(0xFF16161F);    // Cards / inputs
  static const violet = Color(0xFF7C5CFF);     // Gradient start
  static const blue = Color(0xFF46B6FF);       // Gradient end
  static const moneyGreen = Color(0xFF34D39A); // Balance / succès
  static const gold = Color(0xFFC9A84C);       // Accent premium
  static const text = Color(0xFFF4F3EF);
  static const muted = Color(0xFFAEAEC2);
  static const whatsapp = Color(0xFF25D366);
  static const danger = Color(0xFFE9576B);

  static const actionGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [violet, blue],
  );
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      );

  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      );

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.base,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.violet,
        secondary: AppColors.blue,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: TextTheme(
        displayMedium: AppTextStyles.display,
        headlineMedium: AppTextStyles.h1,
        titleMedium: AppTextStyles.h2,
        bodyMedium: AppTextStyles.body,
        labelSmall: AppTextStyles.caption,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        labelStyle: AppTextStyles.caption,
        hintStyle: AppTextStyles.bodyMuted,
      ),
    );
  }
}