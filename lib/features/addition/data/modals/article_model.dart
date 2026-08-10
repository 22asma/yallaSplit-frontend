class ArticleModel {
  final String id;
  final String nom;
  final double prix;
  final int quantite;

  const ArticleModel({
    required this.id,
    required this.nom,
    required this.prix,
    required this.quantite,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      prix: double.parse(json['prix'].toString()),
      quantite: json['quantite'] as int? ?? 1,
    );
  }
}