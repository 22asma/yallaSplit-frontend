import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';
import 'package:yallasplit_app/core/storage/secure_storage_service.dart';
import 'package:yallasplit_app/features/auth/domain/auth_repository.dart';
import 'package:yallasplit_app/features/auth/data/datasource/auth_api_service.dart';
import 'package:yallasplit_app/features/auth/data/models/auth_dtos.dart';
import 'package:yallasplit_app/features/auth/data/models/auth_response_model.dart';
import 'package:yallasplit_app/features/auth/data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _api;
  final SecureStorageService _storage;
  final Dio _dio;

  AuthRepositoryImpl({
    required AuthApiService api,
    required SecureStorageService storage,
    required Dio dio,
  })  : _api = api,
        _storage = storage,
        _dio = dio;

  @override
  Future<RegisterResultModel> register(RegisterRequestDto dto) {
    return _api.register(dto);
  }

  @override
  Future<AuthSessionModel> login(LoginRequestDto dto) async {
    final session = await _api.login(dto);
    await _storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.clearTokens();
    }
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequestDto dto) {
    return _api.forgotPassword(dto);
  }

  @override
  Future<void> resetPassword(ResetPasswordRequestDto dto) {
    return _api.resetPassword(dto);
  }

  @override
  Future<void> changePassword(ChangePasswordRequestDto dto) {
    return _api.changePassword(dto);
  }

  @override
  Future<void> sendVerificationEmail() {
    return _api.sendVerificationEmail();
  }

  @override
  Future<void> verifyEmail(VerifyEmailRequestDto dto) {
    return _api.verifyEmail(dto);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.me);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  @override
  Future<bool> hasActiveSession() {
    return _storage.hasSession();
  }
}