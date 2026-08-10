import 'package:yallasplit_app/features/auth/data/models/auth_dtos.dart';
import 'package:yallasplit_app/features/auth/data/models/auth_response_model.dart';
import 'package:yallasplit_app/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<RegisterResultModel> register(RegisterRequestDto dto);
  Future<AuthSessionModel> login(LoginRequestDto dto);
  Future<void> logout();

  Future<void> forgotPassword(ForgotPasswordRequestDto dto);
  Future<void> resetPassword(ResetPasswordRequestDto dto);
  Future<void> changePassword(ChangePasswordRequestDto dto);

  Future<void> sendVerificationEmail();
  Future<void> verifyEmail(VerifyEmailRequestDto dto);

  /// Récupère le profil complet (GET /users/me) — utile après login/refresh
  /// pour avoir nom/telephone/emailVerified, pas juste userId+email.
  Future<UserModel> getCurrentUser();

  /// Vérifie s'il existe une session locale valide (refresh token présent)
  /// -> utilisé au démarrage de l'app pour savoir si on va direct à l'accueil ou au login.
  Future<bool> hasActiveSession();
}