import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/core/errors/app_exception.dart';
import 'package:yallasplit_app/features/auth/data/models/auth_dtos.dart';
import 'package:yallasplit_app/features/auth/domain/auth_repository.dart';
import 'package:yallasplit_app/features/notification/services/push_notification_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final PushNotificationService _pushService; // <-- cette ligne doit être présente

  AuthNotifier(this._repository, this._pushService) : super(const AuthState()) { // <-- 2 paramètres ici
    _checkInitialSession();
  }


  /// Appelé une fois au démarrage de l'app.
  Future<void> _checkInitialSession() async {
  final hasSession = await _repository.hasActiveSession();
  if (!hasSession) {
    state = state.copyWith(status: AuthStatus.unauthenticated);
    return;
  }
  try {
    final user = await _repository.getCurrentUser();
    state = state.copyWith(status: AuthStatus.authenticated, user: user);
  } catch (_) {
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }
}

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.login(LoginRequestDto(email: email, password: password));
      final user = await _repository.getCurrentUser();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);

      // Enregistre le device token une fois connecté
      await _pushService.initAndRegister();

      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    }
  }

  /// Retourne true si l'inscription a réussi (ne connecte PAS automatiquement,
  /// cf. décision prise plus tôt : l'utilisateur doit vérifier son email d'abord).
  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    String? telephone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.register(
        RegisterRequestDto(
          email: email,
          password: password,
          nom: nom,
          telephone: telephone,
        ),
      );
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    }
  }

 Future<void> logout() async {
    await _pushService.unregister(); // retire le token avant de couper la session
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Appelé par l'interceptor via le callback onSessionExpired (voir dio_client.dart)
  void forceLogout() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Votre session a expiré, veuillez vous reconnecter.',
    );
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _repository.forgotPassword(ForgotPasswordRequestDto(email: email));
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> resetPassword({required String token, required String newPassword}) async {
    try {
      await _repository.resetPassword(
        ResetPasswordRequestDto(token: token, newPassword: newPassword),
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        ChangePasswordRequestDto(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> sendVerificationEmail() async {
    try {
      await _repository.sendVerificationEmail();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    try {
      await _repository.verifyEmail(VerifyEmailRequestDto(token: token));
      // Si l'utilisateur était déjà connecté, on rafraîchit son profil (emailVerified: true)
      if (state.user != null) {
        final user = await _repository.getCurrentUser();
        state = state.copyWith(user: user);
      }
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}