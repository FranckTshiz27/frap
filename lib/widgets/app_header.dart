import 'package:flutter/material.dart';
import 'package:mobile_fp/widgets/app_logo.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  static const logoHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    return const AppLogo(height: logoHeight);
  }
}
