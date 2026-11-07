import 'package:flutter/material.dart';

class HomeLayout {
  const HomeLayout({
    required this.horizontalPadding,
    required this.headerGap,
    required this.sectionGap,
    required this.featureGap,
  });

  final double horizontalPadding;
  final double headerGap;
  final double sectionGap;
  final double featureGap;

  static const headerTopSpacing = 8.0;

  factory HomeLayout.from(BoxConstraints constraints) {
    final compact = constraints.maxHeight < 700;
    final narrow = constraints.maxWidth < 360;

    return HomeLayout(
      horizontalPadding: narrow ? 20 : 28,
      headerGap: compact ? (narrow ? 10 : 14) : 32,
      sectionGap: compact ? (narrow ? 12 : 16) : 28,
      featureGap: compact ? (narrow ? 8 : 10) : 16,
    );
  }
}
