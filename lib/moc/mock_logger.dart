import 'package:flutter/foundation.dart';

import '../core/logging/app_log_file.dart';

/// Логи режима мок-бэкенда: префикс `[MOCK]`, в файл сессии и в консоль (не release).
abstract final class MockLogger {
  static void log(String message) {
    final line = '[MOCK] $message';
    if (!kReleaseMode) {
      debugPrint(line);
    }
    AppLogFile.writeln(line);
  }

  static String summarizeResponseData(dynamic data) {
    if (data == null) return 'null';
    if (data is List<int>) {
      return 'bytes(len=${data.length})';
    }
    if (data is List) return 'list(len=${data.length})';
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      final keys = m.keys.take(12).join(', ');
      final more = m.length > 12 ? '…' : '';
      // Частые поля для расписания/пропусков
      final schedule = m['schedule'];
      final semesters = m['semesters'];
      final extra = <String>[];
      if (schedule is List) extra.add('schedule.len=${schedule.length}');
      if (semesters is List) extra.add('semesters.len=${semesters.length}');
      if (m.containsKey('total_absences')) {
        extra.add('total_absences=${m['total_absences']}');
      }
      final tail = extra.isEmpty ? '' : ' | ${extra.join(', ')}';
      return 'map(keys=[$keys$more])$tail';
    }
    final s = data.toString();
    if (s.length > 400) return '${s.substring(0, 400)}…';
    return s;
  }
}
