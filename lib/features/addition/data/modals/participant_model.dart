class ParticipantModel {
  final String id;
  final String nom;
  final String? telephone;
  final double? montant;
  final String? statutPaiement; // "EN_ATTENTE" | "PAYE" | "ANNULE" | null (pas encore calculé)

  const ParticipantModel({
    required this.id,
    required this.nom,
    this.telephone,
    this.montant,
    this.statutPaiement,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    final repartition = json['repartition'] as Map<String, dynamic>?;
    return ParticipantModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String?,
      montant: repartition != null ? double.parse(repartition['montant'].toString()) : null,
      statutPaiement: repartition?['statut'] as String?,
    );
  }

  bool get aPaye => statutPaiement == 'PAYE';
}