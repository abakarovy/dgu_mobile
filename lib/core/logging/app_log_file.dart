import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Файл логов сеанса.
///
/// **Папка проекта на ПК** возможна только когда Dart выполняется на той же машине:
/// - `flutter run -d windows` / `linux` / `macos` в debug: пишем в `<корень проекта>/logs/app_logs.txt`
///   (рабочая директория процесса обычно совпадает с каталогом проекта в IDE).
/// - Явный путь: `flutter run --dart-define=DGU_LOG_DIR=C:\path\to\project\logs` (удобно для desktop).
///
/// На **Android/iOS** путь к диску ПК недоступен — логи остаются в каталоге приложения
/// (`getApplicationSupportDirectory`), пока не зададите [DGU_LOG_DIR] и реально доступный
/// на устройстве каталог (например, внешнее хранилище).
class AppLogFile {
  AppLogFile._();

  static IOSink? _sink;
  static bool _prepared = false;

  /// Абсолютный путь к каталогу логов из `dart-define` (пусто = не задано).
  static const String _logDirFromDefine = String.fromEnvironment(
    'DGU_LOG_DIR',
    defaultValue: '',
  );

  static bool _isDesktopHost() {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  /// Пробуем писать в каталог на машине разработчика (ПК).
  static Future<File?> _tryPcProjectLogFile() async {
    if (kIsWeb) return null;

    if (_logDirFromDefine.trim().isNotEmpty) {
      try {
        final dir = Directory(_logDirFromDefine.trim());
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}${Platform.pathSeparator}app_logs.txt');
        await file.writeAsString('', flush: true);
        return file;
      } catch (_) {
        // Неверный путь на устройстве и т.п. — ниже fallback.
        return null;
      }
    }

    if (kDebugMode && _isDesktopHost()) {
      try {
        final cwd = Directory.current.path;
        final dir = Directory('$cwd${Platform.pathSeparator}logs');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}${Platform.pathSeparator}app_logs.txt');
        await file.writeAsString('', flush: true);
        return file;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static Future<void> prepareNewSession() async {
    if (kIsWeb) return;
    if (_prepared) return;
    _prepared = true;
    try {
      await _sink?.flush();
      await _sink?.close();
      _sink = null;

      final pcFile = await _tryPcProjectLogFile();
      final File file;
      if (pcFile != null) {
        file = pcFile;
      } else {
        final dir = await getApplicationSupportDirectory();
        file = File('${dir.path}/app_logs.txt');
        await file.writeAsString('', flush: true);
      }
      _sink = file.openWrite(mode: FileMode.append);
    } catch (_) {
      _sink = null;
    }
  }

  static void writeln(String line) {
    if (kIsWeb) return;
    final s = _sink;
    if (s == null) return;
    try {
      final ts = DateTime.now().toIso8601String();
      s.writeln('[$ts] $line');
    } catch (_) {}
  }

  static Future<void> flush() async {
    try {
      await _sink?.flush();
    } catch (_) {}
  }
}
