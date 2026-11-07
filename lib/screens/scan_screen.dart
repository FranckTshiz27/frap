import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_fp/crypto/crypto_matrice_service.dart';
import 'package:mobile_fp/screens/scan_result_screen.dart';
import 'package:mobile_fp/theme/app_colors.dart';
import 'package:mobile_fp/theme/app_typography.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _CameraAccess { checking, denied, ready }

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  MobileScannerController? _controller;

  _CameraAccess _cameraAccess = _CameraAccess.checking;
  bool _isProcessing = false;
  bool _codeDetected = false;
  bool _torchEnabled = false;
  String? _latestRawValue;
  int _scannerKey = 0;
  double _zoomScale = 0;
  Timer? _autoScanTimer;
  Timer? _lostDetectionTimer;
  Timer? _refocusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameraAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScanTimer?.cancel();
    _lostDetectionTimer?.cancel();
    _refocusTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _cameraAccess != _CameraAccess.ready) {
      _initCameraAccess();
    }
  }

  MobileScannerController _createController() {
    return MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
      lensType: CameraLensType.any,
      autoZoom: true,
      // Sans résolution explicite, Android reste en 640x480 — insuffisant
      // pour un Data Matrix dense (~144x144 modules).
      cameraResolution: const Size(1920, 1080),
      formats: const [BarcodeFormat.dataMatrix],
    );
  }

  Future<void> _prepareCameraForScan() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    for (var attempt = 0; attempt < 30; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (controller.value.isRunning) {
        break;
      }
    }

    if (!controller.value.isRunning || !mounted) {
      return;
    }

    await controller.setFocusPoint(const Offset(0.5, 0.5));
    _startRefocusTimer();
  }

  void _startRefocusTimer() {
    _refocusTimer?.cancel();
    _refocusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final controller = _controller;
      if (controller == null ||
          !controller.value.isRunning ||
          _isProcessing ||
          !mounted) {
        return;
      }
      await controller.setFocusPoint(const Offset(0.5, 0.5));
    });
  }

  String? _readBarcodeValue(Barcode barcode) {
    for (final value in [barcode.rawValue, barcode.displayValue]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  bool _isCachetBarcode(Barcode barcode) {
    final value = _readBarcodeValue(barcode);
    if (value == null) {
      return false;
    }

    if (barcode.format == BarcodeFormat.dataMatrix) {
      return true;
    }

    return CryptoMatriceService.estPayloadScanValide(value);
  }

  Future<void> _adjustZoom(double delta) async {
    final controller = _controller;
    if (controller == null || !controller.value.isRunning) {
      return;
    }

    final nextZoom = (_zoomScale + delta).clamp(0.0, 1.0);
    if (nextZoom == _zoomScale) {
      return;
    }

    await controller.setZoomScale(nextZoom);
    if (!mounted) {
      return;
    }
    setState(() => _zoomScale = nextZoom);
  }

  Future<void> _initCameraAccess() async {
    if (!mounted) {
      return;
    }

    setState(() => _cameraAccess = _CameraAccess.checking);

    var status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      _controller?.dispose();
      _controller = null;
      setState(() => _cameraAccess = _CameraAccess.denied);
      return;
    }

    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (!mounted) {
      return;
    }

    if (!status.isGranted) {
      _controller?.dispose();
      _controller = null;
      setState(() => _cameraAccess = _CameraAccess.denied);
      return;
    }

    // Laisse le système libérer la caméra après la boîte de dialogue de permission.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) {
      return;
    }

    _controller?.dispose();
    _controller = _createController();
    setState(() {
      _cameraAccess = _CameraAccess.ready;
      _scannerKey++;
    });
    unawaited(_prepareCameraForScan());
  }

  Future<void> _retryCameraAccess() async {
    if (await Permission.camera.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    await _initCameraAccess();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) {
      return;
    }

    String? rawValue;
    var bestScore = -1.0;

    for (final barcode in capture.barcodes) {
      if (!_isCachetBarcode(barcode)) {
        continue;
      }

      final candidate = _readBarcodeValue(barcode);
      if (candidate == null) {
        continue;
      }

      final area = barcode.size.width * barcode.size.height;
      final score = area > 0
          ? area
          : (barcode.format == BarcodeFormat.dataMatrix ? 1.0 : 0.5);
      if (rawValue == null || score > bestScore) {
        bestScore = score;
        rawValue = candidate;
      }
    }

    if (rawValue == null) {
      if (_latestRawValue != null && _lostDetectionTimer == null) {
        _lostDetectionTimer = Timer(const Duration(milliseconds: 900), () {
          _lostDetectionTimer = null;
          if (!mounted || _isProcessing) {
            return;
          }
          _autoScanTimer?.cancel();
          setState(() {
            _codeDetected = false;
            _latestRawValue = null;
          });
        });
      }
      return;
    }

    _lostDetectionTimer?.cancel();
    _lostDetectionTimer = null;

    _latestRawValue = rawValue;
    if (mounted && !_codeDetected) {
      setState(() => _codeDetected = true);
    }

    _autoScanTimer?.cancel();
    _autoScanTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _isProcessing || _latestRawValue != rawValue) {
        return;
      }
      unawaited(_processBarcode(rawValue!));
    });
  }

  Future<void> _toggleTorch() async {
    await _controller?.toggleTorch();
    if (!mounted) {
      return;
    }
    setState(() => _torchEnabled = !_torchEnabled);
  }

  Future<void> _triggerScan() async {
    if (_isProcessing) {
      return;
    }

    if (_cameraAccess != _CameraAccess.ready) {
      await _initCameraAccess();
      return;
    }

    final rawValue = _latestRawValue;
    if (rawValue == null || rawValue.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aucun cachet électronique détecté. Placez-le dans le cadre puis réessayez.',
            ),
          ),
        );
      }
      return;
    }

    await _processBarcode(rawValue);
  }

  Future<void> _processBarcode(String rawValue) async {
    _autoScanTimer?.cancel();
    _lostDetectionTimer?.cancel();
    _lostDetectionTimer = null;
    setState(() => _isProcessing = true);
    await _controller?.stop();

    try {
      final resultat = CryptoMatriceService.dechiffrerFicheScan(rawValue);
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ScanResultScreen(resultat: resultat),
        ),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cachet électronique non reconnu',
              style: AppTypography.scanInstruction,
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _codeDetected = false;
          _latestRawValue = null;
        });
        if (_cameraAccess == _CameraAccess.ready) {
          await _controller?.start();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.backgroundDeep,
            ],
          ),
        ),
        child: Stack(
          children: [
            const _ScanBackgroundBlobs(),
            SafeArea(
              child: Column(
                children: [
                  _ScanHeader(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 8),
                  Text(
                    'Scannez le cachet électronique de l\'agent',
                    style: AppTypography.scanSubtitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: switch (_cameraAccess) {
                        _CameraAccess.checking => const _CameraPlaceholder(),
                        _CameraAccess.denied => _PermissionDenied(
                            onRetry: _retryCameraAccess,
                          ),
                        _CameraAccess.ready => _ScanViewfinder(
                            key: ValueKey(_scannerKey),
                            controller: _controller!,
                            onDetect: _onDetect,
                            isProcessing: _isProcessing,
                            codeDetected: _codeDetected,
                          ),
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _cameraAccess == _CameraAccess.denied
                          ? 'Autorisez la caméra pour scanner'
                          : _cameraAccess == _CameraAccess.checking
                              ? 'Initialisation de la caméra...'
                              : _isProcessing
                                  ? 'Décodage en cours...'
                                  : _codeDetected
                                      ? 'Cachet détecté — lecture automatique...'
                                      : 'Centrez le cachet dans le cadre, rapprochez à 10-15 cm et ajustez le zoom ou la lampe',
                      style: AppTypography.scanInstruction,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ZoomButton(
                        icon: Icons.remove,
                        enabled: _cameraAccess == _CameraAccess.ready &&
                            !_isProcessing &&
                            _zoomScale > 0,
                        onPressed: () => _adjustZoom(-0.1),
                      ),
                      const SizedBox(width: 12),
                      _TorchButton(
                        enabled: _cameraAccess == _CameraAccess.ready &&
                            !_isProcessing,
                        active: _torchEnabled,
                        onPressed: _toggleTorch,
                      ),
                      const SizedBox(width: 20),
                      _ScanActionButton(
                        enabled: !_isProcessing &&
                            _cameraAccess == _CameraAccess.ready,
                        codeDetected: _codeDetected,
                        onPressed: _triggerScan,
                      ),
                      const SizedBox(width: 20),
                      _ZoomButton(
                        icon: Icons.add,
                        enabled: _cameraAccess == _CameraAccess.ready &&
                            !_isProcessing &&
                            _zoomScale < 1,
                        onPressed: () => _adjustZoom(0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _ScanFooter(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = _viewfinderSide(constraints);
        return SizedBox(
          width: side,
          height: side,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.viewfinderOverlay,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
        );
      },
    );
  }
}

double _viewfinderSide(BoxConstraints constraints) {
  final maxSide = math.min(constraints.maxWidth, constraints.maxHeight);
  return maxSide.clamp(300, 520);
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.viewfinderOverlay,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                'Accès caméra requis',
                style: AppTypography.scanInstruction,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentDark,
                ),
                child: const Text('Autoriser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanBackgroundBlobs extends StatelessWidget {
  const _ScanBackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -80,
          child: _blob(240),
        ),
        Positioned(
          bottom: -70,
          left: -90,
          child: _blob(280),
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
        color: AppColors.blob.withValues(alpha: 0.35),
      ),
    );
  }
}

class _ScanHeader extends StatelessWidget {
  const _ScanHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: AppColors.logoBackground,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'FRAP',
              style: AppTypography.scanLogo,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanViewfinder extends StatelessWidget {
  const _ScanViewfinder({
    super.key,
    required this.controller,
    required this.onDetect,
    required this.isProcessing,
    required this.codeDetected,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final bool isProcessing;
  final bool codeDetected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final guideSide = _viewfinderSide(constraints);
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: controller,
                onDetect: onDetect,
                fit: BoxFit.cover,
                tapToFocus: true,
                errorBuilder: (context, error) {
                  return ColoredBox(
                    color: AppColors.viewfinderOverlay,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Caméra indisponible',
                          style: AppTypography.scanInstruction,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (isProcessing)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              Center(
                child: SizedBox(
                  width: guideSide,
                  height: guideSide,
                  child: CustomPaint(
                    painter: _CornerBracketPainter(
                      color: codeDetected
                          ? AppColors.statusGreen
                          : AppColors.accent,
                      strokeWidth: 4,
                      cornerLength: 32,
                      radius: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const inset = 8.0;

    _drawCorner(canvas, paint, inset, inset, cornerLength, true, true);
    _drawCorner(
      canvas,
      paint,
      size.width - inset,
      inset,
      cornerLength,
      false,
      true,
    );
    _drawCorner(
      canvas,
      paint,
      inset,
      size.height - inset,
      cornerLength,
      true,
      false,
    );
    _drawCorner(
      canvas,
      paint,
      size.width - inset,
      size.height - inset,
      cornerLength,
      false,
      false,
    );
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double length,
    bool left,
    bool top,
  ) {
    final path = Path();
    if (left && top) {
      path.moveTo(x, y + length);
      path.lineTo(x, y + radius);
      path.quadraticBezierTo(x, y, x + radius, y);
      path.lineTo(x + length, y);
    } else if (!left && top) {
      path.moveTo(x - length, y);
      path.lineTo(x - radius, y);
      path.quadraticBezierTo(x, y, x, y + radius);
      path.lineTo(x, y + length);
    } else if (left && !top) {
      path.moveTo(x + length, y);
      path.lineTo(x + radius, y);
      path.quadraticBezierTo(x, y, x, y - radius);
      path.lineTo(x, y - length);
    } else {
      path.moveTo(x, y - length);
      path.lineTo(x, y - radius);
      path.quadraticBezierTo(x, y, x - radius, y);
      path.lineTo(x - length, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.logoBackground.withValues(alpha: enabled ? 1 : 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _TorchButton extends StatelessWidget {
  const _TorchButton({
    required this.onPressed,
    required this.enabled,
    required this.active,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accent : AppColors.logoBackground,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            active ? Icons.flashlight_on : Icons.flashlight_off_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _ScanActionButton extends StatelessWidget {
  const _ScanActionButton({
    required this.onPressed,
    required this.enabled,
    required this.codeDetected,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final bool codeDetected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? (codeDetected ? AppColors.statusGreen : AppColors.accent)
              : AppColors.accent.withValues(alpha: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.center_focus_strong,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

class _ScanFooter extends StatelessWidget {
  const _ScanFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.statusGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Système actif', style: AppTypography.scanStatus),
                ],
              ),
              Text('© 2026 FRAP', style: AppTypography.scanStatus),
            ],
          ),
        ],
      ),
    );
  }
}
