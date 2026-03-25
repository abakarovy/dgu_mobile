import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Нативный выбор периода на Android (MaterialDatePicker) и iOS (UIDatePicker).
/// На web, Windows, Linux, macOS — стандартный [showDateRangePicker] из Flutter/Material.
Future<DateTimeRange?> showNativeOrMaterialDateRangePicker({
  required BuildContext context,
  required DateTimeRange initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  if (kIsWeb) {
    return showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialDateRange,
    );
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      try {
        const channel = MethodChannel('dgu_mobile/date_range');
        final map = await channel.invokeMethod<Map<dynamic, dynamic>>(
          'pickDateRange',
          <String, dynamic>{
            'startMillis': initialDateRange.start.millisecondsSinceEpoch,
            'endMillis': initialDateRange.end.millisecondsSinceEpoch,
            'firstMillis': firstDate.millisecondsSinceEpoch,
            'lastMillis': lastDate.millisecondsSinceEpoch,
          },
        );
        if (map == null) return null;
        final s = map['startMillis'];
        final e = map['endMillis'];
        if (s is! num || e is! num) return null;
        return DateTimeRange(
          start: DateTime.fromMillisecondsSinceEpoch(s.toInt()),
          end: DateTime.fromMillisecondsSinceEpoch(e.toInt()),
        );
      } on PlatformException {
        if (!context.mounted) return null;
        return showDateRangePicker(
          context: context,
          firstDate: firstDate,
          lastDate: lastDate,
          initialDateRange: initialDateRange,
        );
      }
    default:
      return showDateRangePicker(
        context: context,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDateRange: initialDateRange,
      );
  }
}
