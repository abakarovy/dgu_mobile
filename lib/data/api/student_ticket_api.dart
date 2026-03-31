import 'package:dio/dio.dart';

import '../models/student_ticket_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

class StudentTicketApi {
  StudentTicketApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/mobile/student-ticket
  Future<StudentTicketModel> getMyTicket() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile/student-ticket',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final data = res.data;
      final map = (data is Map<String, dynamic>)
          ? data
          : (data is Map)
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
      final inner = (map['ticket'] is Map) ? Map<String, dynamic>.from(map['ticket'] as Map) : map;
      return StudentTicketModel.fromJson(inner);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

