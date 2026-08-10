class UserModel {
  final String userId;
  final String email;
  final String nom;
  final String? telephone;
  final bool emailVerified;
  final DateTime dateInscription;

  const UserModel({
    required this.userId,
    required this.email,
    required this.nom,
    this.telephone,
    required this.emailVerified,
    required this.dateInscription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      dateInscription: DateTime.parse(json['dateInscription'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'nom': nom,
      'telephone': telephone,
      'emailVerified': emailVerified,
      'dateInscription': dateInscription.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? nom,
    String? telephone,
    bool? emailVerified,
  }) {
    return UserModel(
      userId: userId,
      email: email,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      emailVerified: emailVerified ?? this.emailVerified,
      dateInscription: dateInscription,
    );
  }
}