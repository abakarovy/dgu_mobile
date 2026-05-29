import 'package:dio/dio.dart';

import '../../core/cache/json_cache.dart';
import '../../core/constants/api_constants.dart';
import 'college_site_content.dart';
import 'college_site_fallback.dart';
import 'college_site_parser.dart';

/// Загрузка и кэширование публичного контента college.dgu.ru.
class CollegeSiteService {
  CollegeSiteService({
    required JsonCache cache,
    Dio? dio,
  })  : _cache = cache,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {'Accept': 'text/html,application/xhtml+xml'},
              ),
            );

  static const cacheKey = 'college_site:home';

  final JsonCache _cache;
  final Dio _dio;

  Future<CollegeSiteContent> loadHome({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _readCached();
      if (cached != null) return cached;
    }

    try {
      final response = await _dio.get<String>(
        '${ApiConstants.collegeSiteOrigin}/',
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data ?? '';
      if (html.isEmpty) throw StateError('empty html');
      final parsed = CollegeSiteParser.parseHomeHtml(
        html,
        fetchedAt: DateTime.now(),
      );
      await _cache.setJson(cacheKey, parsed.toJson());
      return parsed;
    } catch (_) {
      final cached = _readCached();
      if (cached != null) return cached;
      return CollegeSiteFallback.defaultContent;
    }
  }

  CollegeSiteContent? _readCached() {
    final map = _cache.getJsonMap(cacheKey);
    if (map == null) return null;
    try {
      return CollegeSiteContent.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
