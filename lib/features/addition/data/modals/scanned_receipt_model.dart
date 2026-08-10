class ScannedArticle {
  final String nom;
  final double prix;
  final int quantite;

  const ScannedArticle({
    required this.nom,
    required this.prix,
    required this.quantite,
  });

  factory ScannedArticle.fromJson(Map<String, dynamic> json) {
    return ScannedArticle(
      nom: json['nom'] as String,
      prix: double.parse(json['prix'].toString()),
      quantite: json['quantite'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {'nom': nom, 'prix': prix, 'quantite': quantite};

  ScannedArticle copyWith({String? nom, double? prix, int? quantite}) {
    return ScannedArticle(
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      quantite: quantite ?? this.quantite,
    );
  }
}

class ScannedReceiptModel {
  final double montantTotal;
  final double taxe;
  final List<ScannedArticle> articles;
  final String imageRecuUrl;

  const ScannedReceiptModel({
    required this.montantTotal,
    required this.taxe,
    required this.articles,
    required this.imageRecuUrl,
  });

  factory ScannedReceiptModel.fromJson(Map<String, dynamic> json) {
    return ScannedReceiptModel(
      montantTotal: double.parse(json['montantTotal'].toString()),
      taxe: double.parse((json['taxe'] ?? 0).toString()),
      articles: (json['articles'] as List<dynamic>? ?? [])
          .map((a) => ScannedArticle.fromJson(a as Map<String, dynamic>))
          .toList(),
      imageRecuUrl: json['imageRecuUrl'] as String? ?? '',
    );
  }
}