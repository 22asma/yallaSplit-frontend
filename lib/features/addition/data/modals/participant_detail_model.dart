class ParticipantArticleAssignment {
  final String id; // id de l'ArticleParticipant
  final String articleId;
  final double partMontant;

  const ParticipantArticleAssignment({
    required this.id,
    required this.articleId,
    required this.partMontant,
  });

  factory ParticipantArticleAssignment.fromJson(Map<String, dynamic> json) {
    return ParticipantArticleAssignment(
      id: json['id'] as String,
      articleId: json['articleId'] as String,
      partMontant: double.parse(json['partMontant'].toString()),
    );
  }
}

class ParticipantDetailModel {
  final String id;
  final String nom;
  final List<ParticipantArticleAssignment> articleParticipants;

  const ParticipantDetailModel({
    required this.id,
    required this.nom,
    required this.articleParticipants,
  });

  factory ParticipantDetailModel.fromJson(Map<String, dynamic> json) {
    return ParticipantDetailModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      articleParticipants: (json['articleParticipants'] as List<dynamic>? ?? [])
          .map((a) => ParticipantArticleAssignment.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}