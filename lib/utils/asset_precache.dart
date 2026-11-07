import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_fp/constants/app_assets.dart';
import 'package:mobile_fp/crypto/crypto_matrice_repository.dart';

class AppAssetCache {
  static Uint8List? logoBytes;
  static ui.Image? logoImage;
}

Future<void> precacheAppAssets() async {
  await CryptoMatriceRepository.load();
  await _precacheLogo();

  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.inter(fontWeight: FontWeight.w400),
      GoogleFonts.inter(fontWeight: FontWeight.w700),
      GoogleFonts.inter(fontWeight: FontWeight.w800),
    ]);
  } catch (_) {
    // Fonts are optional for startup; the logo must remain available.
  }
}

Future<void> _precacheLogo() async {
  AppAssetCache.logoBytes =
      (await rootBundle.load(AppAssets.appLogo)).buffer.asUint8List();

  AppAssetCache.logoImage = await _decodeImage(AppAssetCache.logoBytes!);

  final memoryProvider = MemoryImage(AppAssetCache.logoBytes!);
  final key = await memoryProvider.obtainKey(const ImageConfiguration());
  PaintingBinding.instance.imageCache.putIfAbsent(
    key,
    () => OneFrameImageStreamCompleter(
      SynchronousFuture(ImageInfo(image: AppAssetCache.logoImage!)),
    ),
  );

  await _precacheAssetImage(AppAssets.appLogo);
}

Future<ui.Image> _decodeImage(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}

Future<void> _precacheAssetImage(String asset) async {
  final stream = AssetImage(asset).resolve(const ImageConfiguration());
  final completer = Completer<void>();

  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo info, bool synchronousCall) {
      stream.removeListener(listener);
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
    onError: (Object error, StackTrace? stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    },
  );

  stream.addListener(listener);
  await completer.future;
}
