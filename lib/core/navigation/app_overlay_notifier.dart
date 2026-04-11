import 'package:flutter/foundation.dart';

/// Глобальный счётчик открытых модальных нижних листов (выбор периода и т.п.),
/// чтобы оболочка могла скрыть нижний навбар.
abstract final class AppOverlayNotifier {
  static final ValueNotifier<int> modalBottomSheetDepth = ValueNotifier<int>(0);

  static void _push() {
    modalBottomSheetDepth.value = modalBottomSheetDepth.value + 1;
  }

  static void _pop() {
    final v = modalBottomSheetDepth.value;
    if (v > 0) modalBottomSheetDepth.value = v - 1;
  }

  /// Оборачивает [showModalBottomSheet]: увеличивает счётчик на время показа.
  static Future<T?> wrapModalBottomSheet<T>(
    Future<T?> Function() show,
  ) async {
    _push();
    try {
      return await show();
    } finally {
      _pop();
    }
  }
}
