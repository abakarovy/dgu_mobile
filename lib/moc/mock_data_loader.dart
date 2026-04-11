import 'package:flutter/services.dart';

import 'mock_bundle_embedded.dart';

/// Мок-данные: JSON встроен в [MockBundleEmbedded]; из assets подгружается только фото для 1С.
abstract final class MockDataLoader {
  static Uint8List? _mockAvatarPngBytes;
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  /// PNG для `GET /api/1c/student-photo` (мок).
  static Uint8List? get mockAvatarPngBytes => _mockAvatarPngBytes;

  /// Подгрузка изображения аватара; JSON моков доступен сразу через [accounts]/[payloads].
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final img = await rootBundle.load('assets/images/alibek.png');
      _mockAvatarPngBytes = img.buffer.asUint8List();
    } catch (_) {
      _mockAvatarPngBytes = null;
    }
    _loaded = true;
  }

  static Map<String, dynamic> get accounts => MockBundleEmbedded.accounts;

  static Map<String, dynamic> get payloads => MockBundleEmbedded.payloads;
}
