import 'package:flutter/foundation.dart';

/// Сигналы перезагрузки студенческих модулей по WebSocket (`portfolio`, `scholarship_rating`).
abstract final class StudentModulesRefreshBus {
  static final ValueNotifier<int> portfolioTick = ValueNotifier<int>(0);
  static final ValueNotifier<int> scholarshipRatingTick = ValueNotifier<int>(0);

  static void bumpPortfolio() {
    portfolioTick.value++;
  }

  static void bumpScholarshipRating() {
    scholarshipRatingTick.value++;
  }
}
