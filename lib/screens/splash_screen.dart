import 'package:flutter/material.dart';
import 'package:mobile_fp/screens/home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mobile_fp/theme/app_colors.dart';
import 'package:mobile_fp/layout/home_layout.dart';
import 'package:mobile_fp/widgets/app_header.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 2);
  late final AnimationController _controller;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSplash());
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() => _appVersion = info.version);
  }

  Future<void> _startSplash() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    await _controller.forward().orCancel;
    if (mounted) {
      _goToHome();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackgroundBlobs(),
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
                      Expanded(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return _SplashContent(
                                progress: _controller.value,
                                appVersion: _appVersion,
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Center(
                          child: Text(
                            '© 2026 FRAP · Administration Publique',
                            style: _SplashStyles.footer,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
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

abstract final class _SplashStyles {
  static const title = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const tagline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.3,
    letterSpacing: 2.8,
  );

  static const footer = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.footer,
    height: 1.3,
  );
}

class _SplashBackgroundBlobs extends StatelessWidget {
  const _SplashBackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -90,
          child: _blob(260),
        ),
        Positioned(
          bottom: -80,
          left: -100,
          child: _blob(300),
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
        color: AppColors.blob.withValues(alpha: 0.4),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.progress,
    required this.appVersion,
  });

  final double progress;
  final String appVersion;

  static const _progressWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'FRAP',
          style: _SplashStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Text(
          'RÉPUBLIQUE DÉMOCRATIQUE DU CONGO',
          style: _SplashStyles.tagline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: _progressWidth,
          height: 3,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (appVersion.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Version $appVersion',
            style: _SplashStyles.footer,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
