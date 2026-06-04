import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_release_info.dart';

/// Версия приложения и сведения об устройстве (для `/api/health` и экрана «О приложении»).
final class AppRuntimeInfo {
  AppRuntimeInfo._();

  static final AppRuntimeInfo instance = AppRuntimeInfo._();

  static Future<void>? _loadFuture;

  bool _loaded = false;

  String version = AppReleaseInfo.version;
  String buildNumber = AppReleaseInfo.buildNumber;
  String platformId = 'unknown';
  String deviceLabel = '—';

  int get buildNumberInt => int.tryParse(buildNumber) ?? 0;

  String get versionDisplay => 'Версия $version';

  /// Один общий future на всё приложение (не создавать новый в [FutureBuilder] на каждый build).
  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    if (_loaded) return;

    try {
      final info = await PackageInfo.fromPlatform();
      version = _pickVersion(info.version);
      buildNumber = _pickBuild(info.buildNumber, info.version);
    } catch (_) {
      version = AppReleaseInfo.version;
      buildNumber = AppReleaseInfo.buildNumber;
    }

    platformId = _platformId();
    deviceLabel = await _loadDeviceLabel();
    _loaded = true;
  }

  static String _pickVersion(String fromPackage) {
    final v = fromPackage.trim();
    if (v.isEmpty || v == '0.0.0') return AppReleaseInfo.version;
    // Windows иногда отдаёт "1.1.0+27" целиком в version.
    final plus = v.indexOf('+');
    if (plus > 0) return v.substring(0, plus);
    return v;
  }

  static String _pickBuild(String buildNumber, String versionField) {
    final b = buildNumber.trim();
    if (b.isNotEmpty && b != '0') return b;
    final v = versionField.trim();
    final plus = v.indexOf('+');
    if (plus >= 0 && plus < v.length - 1) {
      return v.substring(plus + 1);
    }
    return AppReleaseInfo.buildNumber;
  }

  /// Query для `GET /api/health` (semver без номера сборки, см. MOBILE_HEALTH_CLIENT.md).
  Map<String, String> toHealthQueryParameters() => {
        'app_version': version,
        'platform': platformId,
        'device_model': deviceLabel,
      };

  bool get isMobileStorePlatform =>
      platformId == 'android' || platformId == 'ios';

  static String _platformId() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  Future<String> _loadDeviceLabel() async {
    if (kIsWeb) return 'Web';

    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        final brand = a.brand.trim();
        final model = a.model.trim();
        final name = [if (brand.isNotEmpty) brand, if (model.isNotEmpty) model]
            .join(' ')
            .trim();
        final release = a.version.release.trim();
        final api = a.version.sdkInt;
        final os = release.isEmpty ? 'Android' : 'Android $release';
        return name.isEmpty ? '$os (API $api)' : '$name · $os (API $api)';
      }
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        final model = i.utsname.machine.trim();
        final sys = i.systemVersion.trim();
        return model.isEmpty ? 'iOS $sys' : '$model · iOS $sys';
      }
      if (Platform.isWindows) {
        final w = await plugin.windowsInfo;
        final name = w.computerName.trim();
        final os = '${w.displayVersion} ${w.buildNumber}'.trim();
        return name.isEmpty ? 'Windows $os' : '$name · Windows $os';
      }
      if (Platform.isMacOS) {
        final m = await plugin.macOsInfo;
        return '${m.model} · macOS ${m.osRelease}';
      }
      if (Platform.isLinux) {
        final l = await plugin.linuxInfo;
        final id = l.prettyName.trim();
        return id.isEmpty ? 'Linux' : id;
      }
    } catch (_) {}

    return platformId;
  }
}
