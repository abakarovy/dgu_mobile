import '../../data/api/api_client.dart';
import '../../data/api/auth_api.dart';
import '../../data/services/token_storage.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Простой DI: инициализация один раз при старте, затем доступ к репозиториям.
abstract final class AppContainer {
  static AuthRepository? _authRepository;

  static Future<void> init() async {
    final tokenStorage = await TokenStorage.create();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final authApi = AuthApi(apiClient: apiClient, tokenStorage: tokenStorage);
    _authRepository = AuthRepositoryImpl(authApi: authApi, tokenStorage: tokenStorage);
  }

  static AuthRepository get authRepository {
    final r = _authRepository;
    if (r == null) throw StateError('AppContainer.init() must be called before using authRepository');
    return r;
  }
}
