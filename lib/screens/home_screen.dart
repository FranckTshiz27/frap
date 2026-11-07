import 'package:flutter/material.dart';
import 'package:mobile_fp/screens/scan_screen.dart';
import 'package:mobile_fp/theme/app_colors.dart';
import 'package:mobile_fp/theme/app_typography.dart';
import 'package:mobile_fp/layout/home_layout.dart';
import 'package:mobile_fp/widgets/app_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundBlobs(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = HomeLayout.from(constraints);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: HomeLayout.headerTopSpacing),
                      const AppHeader(),
                      SizedBox(height: layout.headerGap),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _HeroSection(),
                              SizedBox(height: layout.sectionGap),
                              _FeatureList(featureGap: layout.featureGap),
                              SizedBox(height: layout.sectionGap),
                              _ScanButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const ScanScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _Footer(),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: -60,
          left: -80,
          child: _blob(280),
        ),
        Positioned(
          bottom: 80,
          right: -100,
          child: _blob(320),
        ),
        Positioned(
          bottom: 280,
          left: 40,
          child: _blob(200),
        ),
      ],
    );
  }

  Widget _blob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.blob.withValues(alpha: 0.45),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.headline,
            children: [
              const TextSpan(text: 'Vérifiez l\'authenticité\n'),
              const TextSpan(text: 'des actes publics en\n'),
              TextSpan(text: 'un scan.', style: AppTypography.headlineAccent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Scannez Cachet électronique présent sur votre document pour vérifier '
          'son authenticité et consulter les informations officielles associées.',
          style: AppTypography.body,
        ),
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.featureGap});

  final double featureGap;

  static const _features = [
    (Icons.grid_on, 'Scan du cachet électronique'),
    (Icons.people_outline, 'Consultation des informations de l\'acte'),
    (Icons.verified_user_outlined, 'Vérification de l\'authenticité du document'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, feature) in _features.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index < _features.length - 1 ? featureGap : 0,
            ),
            child: _FeatureItem(
              icon: feature.$1,
              label: feature.$2,
            ),
          ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.featureIconBackground,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: AppTypography.feature),
        ),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentDark,
          minimumSize: const Size(double.infinity, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Scanner le cachet électronique',
                style: AppTypography.button,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward, size: 18, color: AppTypography.button.color),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('© 2026 FRAP', style: AppTypography.footer),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'République démocratique du Congo',
                    style: AppTypography.footer,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
