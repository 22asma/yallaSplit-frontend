import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';
import 'package:yallasplit_app/core/errors/app_exception.dart';
import '../models/auth_dtos.dart';
import '../models/auth_response_model.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  Future<RegisterResultModel> register(RegisterRequestDto dto) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: dto.toJson(),
      );
      return RegisterResultModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<AuthSessionModel> login(LoginRequestDto dto) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: dto.toJson(),
      );
      return AuthSessionModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<RefreshResultModel> refresh(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: RefreshRequestDto(refreshToken: refreshToken).toJson(),
      );
      return RefreshResultModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequestDto dto) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: dto.toJson());
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> resetPassword(ResetPasswordRequestDto dto) async {
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: dto.toJson());
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> changePassword(ChangePasswordRequestDto dto) async {
    try {
      await _dio.post(ApiEndpoints.changePassword, data: dto.toJson());
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await _dio.post(ApiEndpoints.sendVerificationEmail);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> verifyEmail(VerifyEmailRequestDto dto) async {
    try {
      await _dio.get(
        ApiEndpoints.verifyEmail,
        queryParameters: dto.toQueryParams(),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Le backend enveloppe toutes ses réponses dans { data: {...}, meta: {...} }.
  /// On extrait "data" une bonne fois pour toutes ici, pour que les modèles
  /// restent simples et fidèles à la vraie forme de la ressource.
  Map<String, dynamic> _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
      return responseData['data'] as Map<String, dynamic>;
    }
    return responseData as Map<String, dynamic>;
  }

  AppException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    if (e.response?.data != null) {
      return AppException.fromResponseData(e.response!.data, statusCode);
    }
    return AppException(
      code: 'NETWORK_ERROR',
      message: 'Impossible de contacter le serveur. Vérifiez votre connexion.',
      statusCode: 0,
    );
  }
}