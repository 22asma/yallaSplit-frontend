import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';


class PublicDioClient {
  late final Dio dio;

  PublicDioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true, error: true));
  }
}