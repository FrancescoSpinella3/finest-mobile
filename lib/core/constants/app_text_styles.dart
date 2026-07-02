import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// Pre-built GoogleFonts text styles used across the app
class AppText {
  // Montserrat – headings, numbers, labels
  static TextStyle montserrat({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  // Poppins – body, subtitles
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  // Common named styles
  static TextStyle get brandTitle => GoogleFonts.montserrat(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: Colors.white,
      );

  static TextStyle netWorthLabel => GoogleFonts.montserrat(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: Colors.white,
      );

  static TextStyle amount({
    double fontSize = 14,
    Color color = AppColors.lightTextPrimary,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.montserrat(
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
      );

  static TextStyle sectionLabel({Color color = Colors.white70}) =>
      GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: color,
        letterSpacing: 1.5,
      );

  static TextStyle chartLabel({Color? color}) =>
      GoogleFonts.poppins(fontSize: 10, color: color);

  static TextStyle legendLabel() => GoogleFonts.poppins(fontSize: 11);

  static TextStyle toastText() =>
      GoogleFonts.poppins(fontSize: 13, color: Colors.white);
}
