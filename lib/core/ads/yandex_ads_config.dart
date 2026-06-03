import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Настройки Yandex Mobile Ads (нативная реклама в новостях и мероприятиях).
abstract final class YandexAdsConfig {
  YandexAdsConfig._();

  static const String demoNativeAdUnitId = 'demo-native-content-yandex';

  static final RegExp _productionAdUnitId =
      RegExp(r'^R-M-\d+-\d+$', caseSensitive: false);

  static bool isValidAdUnitId(String? raw) {
    final id = raw?.trim() ?? '';
    if (id.isEmpty) return false;
    if (id.startsWith('demo-')) return true;
    return _productionAdUnitId.hasMatch(id);
  }

  static String? _env(String key) {
    final v = dotenv.env[key]?.trim();
    if (v != null && v.isNotEmpty) return v;
    return null;
  }

  static String? _define(String key) {
    final v = String.fromEnvironment(key, defaultValue: '');
    if (v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static String? _resolveRaw(String platformKey, String legacyKey) {
    return _env(platformKey) ?? _define(platformKey) ?? _env(legacyKey) ?? _define(legacyKey);
  }

  /// Android: `R-M-19381333-1` (приложение 19381333 в РСЯ).
  static String get nativeAdUnitIdAndroid {
    final raw = _resolveRaw(
      'YANDEX_NATIVE_AD_UNIT_ID_ANDROID',
      'YANDEX_NATIVE_NEWS_AD_UNIT_ID',
    );
    if (raw == null) return demoNativeAdUnitId;
    if (isValidAdUnitId(raw)) return raw;
    return demoNativeAdUnitId;
  }

  /// iOS: `R-M-19381131-1` (приложение 19381131 в РСЯ).
  static String get nativeAdUnitIdIos {
    final raw = _resolveRaw(
      'YANDEX_NATIVE_AD_UNIT_ID_IOS',
      'YANDEX_NATIVE_NEWS_AD_UNIT_ID',
    );
    if (raw == null) return demoNativeAdUnitId;
    if (isValidAdUnitId(raw)) return raw;
    return demoNativeAdUnitId;
  }

  static String get nativeAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return nativeAdUnitIdAndroid;
      case TargetPlatform.iOS:
        return nativeAdUnitIdIos;
      default:
        return demoNativeAdUnitId;
    }
  }

  static String? get adUnitIdConfigWarning {
    for (final entry in [
      ('YANDEX_NATIVE_AD_UNIT_ID_ANDROID', nativeAdUnitIdAndroid),
      ('YANDEX_NATIVE_AD_UNIT_ID_IOS', nativeAdUnitIdIos),
    ]) {
      final raw = _env(entry.$1);
      if (raw == null) continue;
      if (!isValidAdUnitId(raw)) {
        return '${entry.$1}="$raw" — неверный формат (нужен R-M-…-… или demo-…).';
      }
    }
    return null;
  }

  static bool get adsEnabled {
    final flag = dotenv.env['YANDEX_ADS_ENABLED']?.trim().toLowerCase();
    if (flag == 'false' || flag == '0' || flag == 'no') return false;
    const fromDefine = String.fromEnvironment(
      'YANDEX_ADS_ENABLED',
      defaultValue: '',
    );
    final d = fromDefine.trim().toLowerCase();
    if (d == 'false' || d == '0' || d == 'no') return false;
    return true;
  }

  static bool get showNativeFeedAds => adsEnabled && !kIsWeb;

  /// ID приложения в РСЯ для Android (meta-data в манифесте).
  static String get androidApplicationId {
    final v = _env('YANDEX_ANDROID_APPLICATION_ID') ?? _define('YANDEX_ANDROID_APPLICATION_ID');
    return v ?? '19381333';
  }
}
