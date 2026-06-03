import 'package:dgu_mobile/core/ads/yandex_ads_config.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Нативная реклама Yandex в ленте (новости / мероприятия).
class NativeFeedAdCard extends StatelessWidget {
  const NativeFeedAdCard({
    super.key,
    required this.slotId,
    this.borderRadius = AppUi.newsCardRadius,
  });

  static const String platformViewType = 'dgu_feed_native_ad';

  final int slotId;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!YandexAdsConfig.showNativeFeedAds) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppUi.newsContentPaddingH,
              12,
              AppUi.newsContentPaddingH,
              6,
            ),
            child: Text(
              'РЕКЛАМА',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1.0,
                letterSpacing: 1,
                color: AppColors.caption,
              ),
            ),
          ),
          _AdBody(slotId: slotId),
        ],
      ),
    );
  }
}

class _AdBody extends StatelessWidget {
  const _AdBody({required this.slotId});

  final int slotId;

  @override
  Widget build(BuildContext context) {
    if (!YandexAdsConfig.showNativeFeedAds) {
      return const SizedBox.shrink();
    }

    final params = <String, dynamic>{
      'adUnitId': YandexAdsConfig.nativeAdUnitId,
      'slotId': slotId,
    };

    final width = MediaQuery.sizeOf(context).width;
    const height = 280.0;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return SizedBox(
        width: width,
        height: height,
        child: AndroidView(
          viewType: NativeFeedAdCard.platformViewType,
          creationParams: params,
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        width: width,
        height: height,
        child: UiKitView(
          viewType: NativeFeedAdCard.platformViewType,
          creationParams: params,
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
