class RegisterRequestDto {
  final String email;
  final String password;
  final String nom;
  final String? telephone;

  const RegisterRequestDto({
    required this.email,
    required this.password,
    required this.nom,
    this.telephone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nom': nom,
      if (telephone != null) 'telephone': telephone,
    };
  }
}

class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RefreshRequestDto {
  final String refreshToken;

  const RefreshRequestDto({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}

class ForgotPasswordRequestDto {
  final String email;

  const ForgotPasswordRequestDto({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class ResetPasswordRequestDto {
  final String token;
  final String newPassword;

  const ResetPasswordRequestDto({
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {'token': token, 'newPassword': newPassword};
  }
}

class ChangePasswordRequestDto {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {'currentPassword': currentPassword, 'newPassword': newPassword};
  }
}

class VerifyEmailRequestDto {
  final String token;

  const VerifyEmailRequestDto({required this.token});

  // Utilisé en query param (GET /verify-email?token=...), pas en body
  Map<String, String> toQueryParams() {
    return {'token': token};
  }
}