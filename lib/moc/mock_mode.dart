/// Режим мокового бэкенда: все HTTP-запросы обрабатываются локально ([MockDioInterceptor]).
///
/// Переключатель задаётся в [main.dart] **до** [AppContainer.init].
bool useMockBackend = false;
