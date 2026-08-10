import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';
import 'package:yallasplit_app/core/errors/app_exception.dart';

class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  Future<void> registerDeviceToken({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.deviceToken,
        data: {'fcmToken': fcmToken, 'platform': platform},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> removeDeviceToken(String fcmToken) async {
    try {
      await _dio.delete(
        ApiEndpoints.deviceToken,
        queryParameters: {'fcmToken': fcmToken},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    if (e.response?.data != null) {
      return AppException.fromResponseData(e.response!.data, statusCode);
    }
    return AppException(
      code: 'NETWORK_ERROR',
      message: 'Impossible de contacter le serveur.',
      statusCode: 0,
    );
  }
}