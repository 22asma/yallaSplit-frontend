class ArticlePrisPar {
  final String participantId;
  final String nom;
  final double partMontant;
  final bool paye;

  const ArticlePrisPar({
    required this.participantId,
    required this.nom,
    required this.partMontant,
    required this.paye,
  });

  factory ArticlePrisPar.fromJson(Map<String, dynamic> json) {
    return ArticlePrisPar(
      participantId: json['participantId'] as String,
      nom: json['nom'] as String,
      partMontant: double.parse(json['partMontant'].toString()),
      paye: json['paye'] as bool? ?? false,
    );
  }
}

class PublicArticleModel {
  final String id;
  final String nom;
  final double prix;
  final int quantite;
  final double montantDejaAssigne;
  final bool entierementAssigne;
  final List<ArticlePrisPar> prisPar;

  const PublicArticleModel({
    required this.id,
    required this.nom,
    required this.prix,
    required this.quantite,
    this.montantDejaAssigne = 0,
    this.entierementAssigne = false,
    this.prisPar = const [],
  });

  factory PublicArticleModel.fromJson(Map<String, dynamic> json) {
    return PublicArticleModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      prix: double.parse(json['prix'].toString()),
      quantite: json['quantite'] as int? ?? 1,
      montantDejaAssigne: double.parse((json['montantDejaAssigne'] ?? 0).toString()),
      entierementAssigne: json['entierementAssigne'] as bool? ?? false,
      prisPar: (json['prisPar'] as List<dynamic>? ?? [])
          .map((p) => ArticlePrisPar.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  double get montantTotal => prix * quantite;
  double get montantRestant => (montantTotal - montantDejaAssigne).clamp(0, montantTotal);

  bool get dejaPaye => prisPar.any((p) => p.paye);

  bool aDejaPris(String? participantId) {
    return prisPar.any((p) => p.participantId == participantId);
  }
}

class PublicParticipantSummary {
  final String id;
  final String nom;
  final double? montant;
  final String? statutPaiement;

  const PublicParticipantSummary({
    required this.id,
    required this.nom,
    this.montant,
    this.statutPaiement,
  });

  factory PublicParticipantSummary.fromJson(Map<String, dynamic> json) {
    return PublicParticipantSummary(
      id: json['id'] as String,
      nom: json['nom'] as String,
      montant: json['montant'] != null ? double.parse(json['montant'].toString()) : null,
      statutPaiement: json['statutPaiement'] as String?,
    );
  }

  bool get aPaye => statutPaiement == 'PAYE';
}

class TaxePayeur {
  final String participantId;
  final String nom;
  final bool paye;

  const TaxePayeur({
    required this.participantId,
    required this.nom,
    required this.paye,
  });

  factory TaxePayeur.fromJson(Map<String, dynamic> json) {
    return TaxePayeur(
      participantId: json['participantId'] as String,
      nom: json['nom'] as String,
      paye: json['paye'] as bool? ?? false,
    );
  }
}

class PublicAdditionModel {
  final String additionId;
  final double montantTotal;
  final double taxe;
  final TaxePayeur? taxePayeur;
  final String statut;
  final List<PublicArticleModel> articles;
  final List<PublicParticipantSummary> participants;

  const PublicAdditionModel({
    required this.additionId,
    required this.montantTotal,
    required this.taxe,
    this.taxePayeur,
    required this.statut,
    required this.articles,
    required this.participants,
  });

  factory PublicAdditionModel.fromJson(Map<String, dynamic> json) {
    return PublicAdditionModel(
      additionId: json['additionId'] as String,
      montantTotal: double.parse(json['montantTotal'].toString()),
      taxe: double.parse(json['taxe'].toString()),
      taxePayeur: json['taxePayeur'] != null
          ? TaxePayeur.fromJson(json['taxePayeur'] as Map<String, dynamic>)
          : null,
      statut: json['statut'] as String,
      articles: (json['articles'] as List<dynamic>? ?? [])
          .map((a) => PublicArticleModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => PublicParticipantSummary.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}