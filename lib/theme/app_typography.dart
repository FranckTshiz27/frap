import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_fp/theme/app_colors.dart';

abstract final class AppTypography {
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  static TextStyle get logo => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: Colors.white,
        height: 1.2,
      );

  static TextStyle get headline => GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.12,
        letterSpacing: -0.8,
      );

  static TextStyle get headlineAccent => headline.copyWith(
        color: AppColors.accent,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.subtitle,
        height: 1.5,
      );

  static TextStyle get feature => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.35,
        letterSpacing: -0.3,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.accentDark,
        height: 1.2,
        letterSpacing: -0.2,
      );

  static TextStyle get footer => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.footer,
        height: 1.3,
      );

  static TextStyle get splashTitle => GoogleFonts.inter(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get splashTitleAccent => splashTitle.copyWith(
        color: AppColors.accent,
      );

  static TextStyle get splashTagline => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.3,
        letterSpacing: 2.8,
      );

  static TextStyle get splashFooter => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.footer,
        height: 1.3,
      );

  static TextStyle get scanLogo => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get scanSubtitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.subtitle,
        height: 1.3,
      );

  static TextStyle get scanInstruction => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.3,
      );

  static TextStyle get scanStatus => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.footer,
        height: 1.3,
      );

  static TextTheme get textTheme => TextTheme(
        displaySmall: headline,
        bodyLarge: body,
        titleMedium: feature,
        labelLarge: button,
        bodySmall: footer,
      );
}
