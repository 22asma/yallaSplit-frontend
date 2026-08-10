import 'article_model.dart'; // <-- vérifie que cette ligne est bien présente

enum StatutAddition { brouillon, validee, repartie, cloturee, annulee }

StatutAddition _statutFromString(String value) {
  switch (value) {
    case 'BROUILLON':
      return StatutAddition.brouillon;
    case 'VALIDEE':
      return StatutAddition.validee;
    case 'REPARTIE':
      return StatutAddition.repartie;
    case 'CLOTUREE':
      return StatutAddition.cloturee;
    case 'ANNULEE':
      return StatutAddition.annulee;
    default:
      return StatutAddition.brouillon;
  }
}

class AdditionModel {
  final String id;
  final double montantTotal;
  final double taxe;
  final StatutAddition statut;
  final String? imageRecuUrl;
  final DateTime dateScan;
  final DateTime createdAt;
  final List<ArticleModel> articles;

  const AdditionModel({
    required this.id,
    required this.montantTotal,
    required this.taxe,
    required this.statut,
    this.imageRecuUrl,
    required this.dateScan,
    required this.createdAt,
    required this.articles,
  });

  factory AdditionModel.fromJson(Map<String, dynamic> json) {
    return AdditionModel(
      id: json['id'] as String,
      montantTotal: double.parse(json['montantTotal'].toString()),
      taxe: double.parse(json['taxe'].toString()),
      statut: _statutFromString(json['statut'] as String),
      imageRecuUrl: json['imageRecuUrl'] as String?,
      dateScan: DateTime.parse(json['dateScan'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      articles: (json['articles'] as List<dynamic>? ?? [])
          .map((a) => ArticleModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  String get statusLabel {
    switch (statut) {
      case StatutAddition.brouillon:
        return 'Draft';
      case StatutAddition.validee:
      case StatutAddition.repartie:
        return 'Collecting';
      case StatutAddition.cloturee:
        return 'Settled';
      case StatutAddition.annulee:
        return 'Cancelled';
    }
  }
}