import 'dart:async';

import 'package:collection/collection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/api_constants.dart';
import '../di/app_container.dart';
import '../logging/app_log_file.dart';

class RealtimeWsClient {
  RealtimeWsClient._();

  static final RealtimeWsClient instance = RealtimeWsClient._();

  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  bool _connecting = false;

  bool get isConnected => _ch != null;

  Future<void> connectIfPossible() async {
    if (_connecting || _ch != null) return;
    final token = await AppContainer.tokenStorage.getToken();
    if (token == null || token.isEmpty) return;

    _connecting = true;
    try {
      final wsUrl = _wsUrl(token);
      AppLogFile.writeln('[WS] connect $wsUrl');
      final ch = WebSocketChannel.connect(Uri.parse(wsUrl));
      _ch = ch;
      _sub = ch.stream.listen(
        (event) => _onMessage(event),
        onError: (e) => _onClosed('error: $e'),
        onDone: () => _onClosed('done'),
      );
    } catch (e) {
      AppLogFile.writeln('[WS] connect failed: $e');
      _onClosed('connect failed');
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _sub?.cancel();
    _sub = null;
    try {
      _ch?.sink.close();
    } catch (_) {}
    _ch = null;
  }

  static String _wsUrl(String token) {
    // baseUrl ends with /api
    final base = ApiConstants.baseUrl;
    final u = Uri.parse(base);
    final scheme = (u.scheme == 'https') ? 'wss' : 'ws';
    final wsBase = u.replace(scheme: scheme, path: '${u.path}/ws');
    return wsBase.replace(queryParameters: {'token': token}).toString();
  }

  void _onClosed(String reason) {
    AppLogFile.writeln('[WS] closed: $reason');
    _sub?.cancel();
    _sub = null;
    _ch = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 8), () {
      _reconnectTimer = null;
      connectIfPossible();
    });
  }

  Future<void> _onMessage(dynamic event) async {
    final s = event?.toString() ?? '';
    if (s.trim().isEmpty) return;
    AppLogFile.writeln('[WS] message: $s');

    // Expected payload:
    // { "v": 1, "type": "data_changed", "resource": "news", "id": 123 }
    // Keep parsing cheap: look for resource substring, then refresh minimal caches.
    final lower = s.toLowerCase();
    final resource = ['news', 'events', 'assignments']
        .firstWhereOrNull((r) => lower.contains('"resource"') && lower.contains(r));
    if (resource == null) return;

    try {
      if (resource == 'news') {
        final fresh = await AppContainer.newsApi.getNews(limit: 30);
        await AppContainer.jsonCache.setJson('news:list', [for (final n in fresh) n.toJson()]);
      } else if (resource == 'events') {
        final fresh = await AppContainer.eventsApi.getEvents();
        await AppContainer.jsonCache.setJson('events:list', [for (final e in fresh) e.toJson()]);
      } else if (resource == 'assignments') {
        final items = await AppContainer.assignmentsApi.getMy(limit: 50);
        await AppContainer.jsonCache.setJson('mobile:assignments:my', [
          for (final a in items)
            {
              'id': a.id,
              'title': a.title,
              'description': a.description,
              'subject': a.subject,
              'deadline_at': a.deadlineAt?.toIso8601String(),
              'created_at': a.createdAt?.toIso8601String(),
              'is_done': a.isDone,
            }
        ]);
      }
    } catch (e) {
      AppLogFile.writeln('[WS] refresh failed: $e');
    }
  }
}

