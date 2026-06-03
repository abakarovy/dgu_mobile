import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import 'college_site_fallback.dart';

/// Прогрев картинок публичного сайта (главная абитуриента).
abstract final class CollegeSiteImagePrefetch {
  /// Ширина декодирования превью направления (≈272×2 для retina).
  static const int directionThumbCacheWidth = 544;

  static ImageProvider directionThumbProvider(String url) {
    return ResizeImage(
      NetworkImage(url),
      width: directionThumbCacheWidth,
    );
  }

  static List<String> get directionImageUrls {
    return [
      for (final d in CollegeSiteFallback.defaultContent.directions)
        if (d.imageUrl != null && d.imageUrl!.trim().isNotEmpty) d.imageUrl!,
    ];
  }

  /// Скачивает и кладёт в [ImageCache] — вызывать на splash (гость).
  static Future<void> prefetchDirectionImages(
    BuildContext context, {
    Duration perImageTimeout = ApiConstants.prefetchRequestTimeout,
  }) async {
    if (!context.mounted) return;
    await Future.wait(
      directionImageUrls.map(
        (url) => _precacheOne(context, url, perImageTimeout),
      ),
    );
  }

  static Future<void> _precacheOne(
    BuildContext context,
    String url,
    Duration timeout,
  ) async {
    if (!context.mounted) return;
    try {
      await precacheImage(directionThumbProvider(url), context).timeout(timeout);
    } catch (_) {}
  }
}
