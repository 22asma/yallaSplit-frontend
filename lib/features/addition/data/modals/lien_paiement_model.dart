class LienPaiementModel {
  final String id;
  final String additionId;
  final String token;
  final String urlSecurisee;
  final String statut;

  const LienPaiementModel({
    required this.id,
    required this.additionId,
    required this.token,
    required this.urlSecurisee,
    required this.statut,
  });

  factory LienPaiementModel.fromJson(Map<String, dynamic> json) {
    return LienPaiementModel(
      id: json['id'] as String,
      additionId: json['additionId'] as String,
      token: json['token'] as String,
      urlSecurisee: json['urlSecurisee'] as String,
      statut: json['statut'] as String,
    );
  }
}