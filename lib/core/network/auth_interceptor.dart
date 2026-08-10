import 'dart:async';

import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/storage/secure_storage_service.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';

/// Callback appelé quand le refresh échoue définitivement (refresh token invalide/expiré)
/// -> l'app doit déconnecter l'utilisateur et le renvoyer vers l'écran de login.
typedef OnSessionExpired = void Function();

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;
  final OnSessionExpired onSessionExpired;

  // Évite que plusieurs requêtes en parallèle déclenchent chacune leur propre refresh
  bool _isRefreshing = false;
  final List<void Function()> _pendingRequests = [];

  AuthInterceptor({
    required Dio dio,
    required SecureStorageService storage,
    required this.onSessionExpired,
  })  : _dio = dio,
        _storage = storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Les routes publiques n'ont pas besoin de token.
    final isPublicRoute = _publicRoutes.any((r) => options.path.contains(r));
    if (!isPublicRoute) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.contains(ApiEndpoints.refresh);

    // Si ce n'est pas un 401, ou si c'est le refresh lui-même qui a échoué -> on abandonne
    if (!isUnauthorized || isRefreshCall) {
      if (isRefreshCall && isUnauthorized) {
        await _storage.clearTokens();
        onSessionExpired();
      }
      return handler.next(err);
    }

    // Un seul refresh à la fois : les requêtes suivantes attendent le résultat.
    if (_isRefreshing) {
      await _waitForRefresh();
      return _retry(err.requestOptions, handler);
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw DioException(requestOptions: err.requestOptions);
      }

      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String;
      await _storage.updateAccessToken(newAccessToken);

      _isRefreshing = false;
      _resolvePendingRequests();

      return _retry(err.requestOptions, handler);
    } catch (_) {
      _isRefreshing = false;
      _resolvePendingRequests();
      await _storage.clearTokens();
      onSessionExpired();
      return handler.next(err);
    }
  }

  Future<void> _retry(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final token = await _storage.getAccessToken();
      requestOptions.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.fetch(requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<void> _waitForRefresh() {
    final completer = Completer<void>();
    _pendingRequests.add(() => completer.complete());
    return completer.future;
  }

  void _resolvePendingRequests() {
    for (final resolve in _pendingRequests) {
      resolve();
    }
    _pendingRequests.clear();
  }

  static const _publicRoutes = [
    ApiEndpoints.register,
    ApiEndpoints.login,
    ApiEndpoints.refresh,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
    ApiEndpoints.verifyEmail,
  ];
}