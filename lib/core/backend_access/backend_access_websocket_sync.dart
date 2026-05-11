import '../realtime/realtime_ws_client.dart';

/// Подключает или рвёт WS при блокировке API, без цикла с [AppContainer]/[ApiClient].
Future<void> syncWebSocketWithBackendAccess(bool blocked) async {
  if (blocked) {
    await RealtimeWsClient.instance.disconnect();
  } else {
    await RealtimeWsClient.instance.connectIfPossible();
  }
}
