/// Réponse de POST /auth/login (et du refresh initial après register+login si tu enchaînes les deux)
class AuthSessionModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn; // secondes
  final AuthUserSummary user;

  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: AuthUserSummary.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Sous-objet "user" renvoyé dans la session (juste userId + email, pas le profil complet)
class AuthUserSummary {
  final String userId;
  final String email;

  const AuthUserSummary({required this.userId, required this.email});

  factory AuthUserSummary.fromJson(Map<String, dynamic> json) {
    return AuthUserSummary(
      userId: json['userId'] as String,
      email: json['email'] as String,
    );
  }
}

/// Réponse de POST /auth/register (pas de tokens ici)
class RegisterResultModel {
  final String userId;
  final String email;
  final String nom;

  const RegisterResultModel({
    required this.userId,
    required this.email,
    required this.nom,
  });

  factory RegisterResultModel.fromJson(Map<String, dynamic> json) {
    return RegisterResultModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      nom: json['nom'] as String,
    );
  }
}

/// Réponse de POST /auth/refresh : { accessToken, expiresIn } uniquement
class RefreshResultModel {
  final String accessToken;
  final int expiresIn;

  const RefreshResultModel({
    required this.accessToken,
    required this.expiresIn,
  });

  factory RefreshResultModel.fromJson(Map<String, dynamic> json) {
    return RefreshResultModel(
      accessToken: json['accessToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }
}