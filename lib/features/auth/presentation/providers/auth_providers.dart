import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/core/network/dio_client.dart';
import 'package:yallasplit_app/core/network/session_controller.dart';
import 'package:yallasplit_app/core/storage/secure_storage_service.dart';
import 'package:yallasplit_app/features/auth/data/datasource/auth_api_service.dart';
import 'package:yallasplit_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:yallasplit_app/features/auth/domain/auth_repository.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';
import 'package:yallasplit_app/features/notification/presentation/providers/notification_providers.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = DioClient(
    storage: storage,
    onSessionExpired: () {
      // Ne dépend plus de authNotifierProvider directement -> plus de cycle.
      ref.read(sessionControllerProvider.notifier).notifySessionExpired();
    },
  );
  return client.dio;
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(authApiServiceProvider),
    storage: ref.watch(secureStorageProvider),
    dio: ref.watch(dioClientProvider),
  );
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(pushNotificationServiceProvider), // ajouté
  );

  ref.listen<int>(sessionControllerProvider, (previous, next) {
    if (previous != null && next != previous) {
      notifier.forceLogout();
    }
  });

  return notifier;
});