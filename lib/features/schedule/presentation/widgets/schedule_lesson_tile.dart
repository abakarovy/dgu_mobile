import 'dart:math' show min;

import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../data/schedule_lesson.dart';

/// Одна пара в списке расписания (макет 402×874, масштаб через [layoutScale]).
class ScheduleLessonTile extends StatelessWidget {
  const ScheduleLessonTile({
    super.key,
    required this.lesson,
    required this.layoutScale,
    this.showBottomDivider = true,
    this.isFirstInList = true,
  });

  final ScheduleLesson lesson;
  final double layoutScale;
  final bool showBottomDivider;
  /// Первая пара в блоке — сверху [vPad]; у следующих верхний отступ 0 (зазор после полосы совпадает с отступом до полосы).
  final bool isFirstInList;

  static double layoutScaleOf(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return min(s.width / 402.0, s.height / 874.0);
  }

  /// Бэк кладёт в `time` строку вида «0 пара» без интервала — показываем время как «—», номер пары — в подписи снизу.
  static bool _timeLooksLikePairPlaceholder(String t) {
    final s = t.trim();
    if (s.isEmpty || s.contains(':')) return false;
    return RegExp(r'^\d+').hasMatch(s) && s.toLowerCase().contains('пара');
  }

  String _startTimeText() {
    final t = lesson.time.trim();
    if (t.isEmpty || t == '--:--') return '—';
    if (_timeLooksLikePairPlaceholder(t)) return '—';
    final parts = t.split(RegExp(r'[-–—]'));
    final first = parts.first.trim();
    if (first.isEmpty) return '—';
    if (_timeLooksLikePairPlaceholder(first)) return '—';
    return first;
  }

  String _pairLabel() {
    final n = lesson.pairNumber;
    if (n == null) return 'ПАРА';
    if (n == 0) return '0 ПАРА';
    return '$n ПАРА'.toUpperCase();
  }

  /// «Абдулханипаева Камила Камильевна» → «Абдулханипаева К.К.»
  /// «Латипова (Аксенова) Татьяна Игоревна» → «Латипова (Аксенова) Т.И.» — скобки сохраняем, инициалы только у имя/отчество после них.
  static String abbreviateTeacherName(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '—';

    final parenMatch = RegExp(r'\([^)]+\)').firstMatch(s);
    if (parenMatch != null) {
      final before = s.substring(0, parenMatch.start).trim();
      final paren = s.substring(parenMatch.start, parenMatch.end);
      final after = s.substring(parenMatch.end).trim();
      final surParts =
          before.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
      final surname = surParts.isNotEmpty ? surParts.first : '';
      final nameParts =
          after.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();

      String twoInitials() {
        if (nameParts.length >= 2) {
          final p0 = nameParts[0].replaceAll('.', '');
          final p1 = nameParts[1].replaceAll('.', '');
          if (p0.isEmpty) return '';
          final i1 = p0.characters.first.toUpperCase();
          if (p1.isEmpty) return '$i1.';
          final i2 = p1.characters.first.toUpperCase();
          return '$i1.$i2.';
        }
        if (nameParts.length == 1) {
          final p0 = nameParts[0].replaceAll('.', '');
          if (p0.isEmpty) return '';
          return '${p0.characters.first.toUpperCase()}.';
        }
        return '';
      }

      final ini = twoInitials();
      if (surname.isEmpty) return s;
      if (ini.isEmpty) return '$surname $paren'.trimRight();
      return '$surname $paren $ini'.trim();
    }

    final parts = s
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) return '—';

    final surname = parts[0];
    String initialAt(int i) {
      if (parts.length <= i) return '';
      final p = parts[i].replaceAll('.', '');
      if (p.isEmpty) return '';
      return p.characters.first.toUpperCase();
    }

    final i1 = initialAt(1);
    final i2 = initialAt(2);
    if (i1.isEmpty && i2.isEmpty) return surname;

    final buf = StringBuffer()..write(surname);
    if (i1.isNotEmpty) buf.write(' $i1.');
    if (i2.isNotEmpty) buf.write('$i2.');
    return buf.toString();
  }

  String _teacherAudLine() {
    final p = lesson.teacher.trim();
    final a = lesson.auditorium.trim();
    final prep = p.isEmpty ? '—' : abbreviateTeacherName(p);
    final aud = a.isEmpty ? '—' : a;
    return 'Преп: $prep • Ауд: $aud';
  }

  @override
  Widget build(BuildContext context) {
    final sc = layoutScale;
    final hPad = 20.0 * sc;
    final vPad = 15.0 * sc;
    final dividerGap = 16.0 * sc;
    final gap2 = 2.0 * sc;
    final gap20 = 20.0 * sc;
    final topPad = isFirstInList ? vPad : 0.0;
    final bottomPad = showBottomDivider ? 0.0 : vPad;

    final timeStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 11.48 * sc,
      height: 1.0,
      color: const Color(0x66000000),
    );
    final pairStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w400,
      fontSize: 8.2 * sc,
      height: 1.0,
      color: const Color(0x66000000),
    );
    final subjectStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 11.48 * sc,
      height: 1.0,
      color: const Color(0xFF000000),
    );
    final metaStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w400,
      fontSize: 9.84 * sc,
      height: 1.2,
      color: const Color(0xFF64748B),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_startTimeText(), style: timeStyle),
                  SizedBox(height: gap2),
                  Text(_pairLabel(), style: pairStyle),
                ],
              ),
              SizedBox(width: gap20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lesson.subject.isEmpty ? '—' : lesson.subject,
                      style: subjectStyle,
                    ),
                    SizedBox(height: gap2),
                    Text(_teacherAudLine(), style: metaStyle),
                  ],
                ),
              ),
            ],
          ),
          if (showBottomDivider) ...[
            SizedBox(height: dividerGap),
            const Divider(
              height: 0.9,
              thickness: 0.9,
              color: Color(0x472563EB),
            ),
            SizedBox(height: dividerGap),
          ],
        ],
      ),
    );
  }
}
