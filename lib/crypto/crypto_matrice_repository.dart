import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mobile_fp/crypto/crypto_matrice_models.dart';

abstract final class CryptoMatriceRepository {
  static const assetPath = 'assets/crypto/db_crypto.json';

  static CryptoMatriceData? _data;

  static CryptoMatriceData get data {
    final loaded = _data;
    if (loaded == null) {
      throw StateError(
        'CryptoMatriceRepository.load() doit être appelé avant utilisation.',
      );
    }
    return loaded;
  }

  static bool get isLoaded => _data != null;

  static Future<void> load({String path = assetPath}) async {
    if (_data != null) {
      return;
    }

    final raw = await rootBundle.loadString(path);
    _data = CryptoMatriceData.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  static void loadFromJson(Map<String, dynamic> json) {
    _data = CryptoMatriceData.fromJson(json);
  }

  static void resetForTest() {
    _data = null;
  }
}
