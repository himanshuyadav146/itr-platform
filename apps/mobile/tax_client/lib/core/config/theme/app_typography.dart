import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static final TextTheme _baseTextTheme = GoogleFonts.interTextTheme(
    const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, height: 1.1),
      displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.1),
      displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.15),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15),
      headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.2),
    ),
  );

  static final TextTheme textTheme = _baseTextTheme.copyWith(
    displayLarge: GoogleFonts.manrope(textStyle: _baseTextTheme.displayLarge),
    displayMedium: GoogleFonts.manrope(textStyle: _baseTextTheme.displayMedium),
    displaySmall: GoogleFonts.manrope(textStyle: _baseTextTheme.displaySmall),
    headlineLarge: GoogleFonts.manrope(textStyle: _baseTextTheme.headlineLarge),
    headlineMedium: GoogleFonts.manrope(textStyle: _baseTextTheme.headlineMedium),
    headlineSmall: GoogleFonts.manrope(textStyle: _baseTextTheme.headlineSmall),
    titleLarge: GoogleFonts.manrope(textStyle: _baseTextTheme.titleLarge),
    titleMedium: GoogleFonts.manrope(textStyle: _baseTextTheme.titleMedium),
    titleSmall: GoogleFonts.manrope(textStyle: _baseTextTheme.titleSmall),
    labelLarge: GoogleFonts.manrope(textStyle: _baseTextTheme.labelLarge),
  );
}
