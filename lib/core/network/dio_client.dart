import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';
import 'package:yallasplit_app/core/storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class DioClient {
  late final Dio dio;

  DioClient({
    required SecureStorageService storage,
    required OnSessionExpired onSessionExpired,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        storage: storage,
        onSessionExpired: onSessionExpired,
      ),
    );

    // Utile en dev pour voir les requêtes/réponses dans la console.
    // À retirer ou conditionner par kDebugMode en prod.
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }
}