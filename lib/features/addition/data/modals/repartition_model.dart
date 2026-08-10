class RepartitionModel {
  final String id;
  final double montant;
  final String statut;

  const RepartitionModel({required this.id, required this.montant, required this.statut});

  factory RepartitionModel.fromJson(Map<String, dynamic> json) {
    return RepartitionModel(
      id: json['id'] as String,
      montant: double.parse(json['montant'].toString()),
      statut: json['statut'] as String,
    );
  }
}