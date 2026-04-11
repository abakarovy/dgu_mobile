import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Справки через `POST/GET /api/documents/...` (JWT, см. MOBILE_SPRAVKI_API.md).
class DocumentsApi {
  DocumentsApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Шаг 1: создать заказ в 1С. Для родителя передайте [studentId] (id студента в БД сайта).
  Future<CertificateOrderCreated> createCertificateOrder({
    required String type,
    required String format,
    required String where,
    String? comment,
    int? studentId,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'format': format,
      'where': where,
      'comment': comment ?? '',
      'student_id': studentId,
    };
    try {
      final res = await _api.dio.post<dynamic>(
        ApiConstants.documentsCertificateOrderPath,
        data: body,
        options: Options(
          validateStatus: (s) => s != null && s < 600,
          contentType: Headers.jsonContentType,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final d = res.data;
      if (d is! Map) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final m = Map<String, dynamic>.from(d);
      final oid = (m['order_id'] ?? m['orderId'] ?? '').toString().trim();
      if (oid.isEmpty) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final rid = m['request_id'] ?? m['requestId'];
      return CertificateOrderCreated(
        orderId: oid,
        status: (m['status'] ?? '').toString(),
        requestId: rid is int ? rid : (rid is num ? rid.toInt() : null),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Шаг 2: `GET /api/documents/certificate-order/{order_id}/status`
  Future<CertificateOrderStatusResult> getCertificateOrderStatus(String orderId) async {
    final path = _orderSubPath(orderId, 'status');
    try {
      final res = await _api.dio.get<dynamic>(
        path,
        options: Options(
          validateStatus: (s) => s != null && s < 600,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final d = res.data;
      if (d is! Map) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final m = Map<String, dynamic>.from(d);
      final oid = (m['order_id'] ?? m['orderId'] ?? orderId).toString();
      final status = (m['status'] ?? '').toString();
      final ready = m['is_ready'] == true || m['isReady'] == true;
      return CertificateOrderStatusResult(orderId: oid, status: status, isReady: ready);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Шаг 3: `GET /api/documents/certificate-order/{order_id}/download` — PDF или `202` если не готово.
  Future<CertificateDownloadResult> downloadCertificatePdf(String orderId) async {
    final path = _orderSubPath(orderId, 'download');
    try {
      final res = await _api.dio.get<List<int>>(
        path,
        options: Options(
          validateStatus: (s) => s != null && (s == 200 || s == 202 || s == 404),
          responseType: ResponseType.bytes,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      final code = res.statusCode ?? 0;
      if (code == 202) {
        return const CertificateDownloadResult.notReady();
      }
      if (code != 200 || res.data == null || res.data!.isEmpty) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      return CertificateDownloadResult.bytes(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// История: `GET /api/documents/certificate-orders`
  Future<List<Map<String, dynamic>>> getCertificateOrders() async {
    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.documentsCertificateOrdersPath,
        options: Options(
          validateStatus: (s) => s != null && s < 600,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final list = _unwrapCertificateOrdersList(res.data);
      if (list == null) return [];
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) e
          else if (e is Map) Map<String, dynamic>.from(e),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Бэк может отдать массив или обёртку `{ "items": [...] }` (не путать с `GET /1c/orders`).
  static List<dynamic>? _unwrapCertificateOrdersList(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    for (final k in ['items', 'certificate_orders', 'data', 'results']) {
      final v = m[k];
      if (v is List) return v;
    }
    return null;
  }

  static String _orderSubPath(String orderId, String suffix) {
    final enc = Uri.encodeComponent(orderId);
    return '${ApiConstants.documentsCertificateOrderPath}/$enc/$suffix';
  }
}

class CertificateOrderCreated {
  const CertificateOrderCreated({
    required this.orderId,
    required this.status,
    this.requestId,
  });

  final String orderId;
  final String status;
  final int? requestId;
}

class CertificateOrderStatusResult {
  const CertificateOrderStatusResult({
    required this.orderId,
    required this.status,
    required this.isReady,
  });

  final String orderId;
  final String status;
  final bool isReady;
}

class CertificateDownloadResult {
  const CertificateDownloadResult.notReady() : bytes = null;

  CertificateDownloadResult.bytes(List<int> this.bytes);

  final List<int>? bytes;

  bool get hasFile => bytes != null && bytes!.isNotEmpty;
}
