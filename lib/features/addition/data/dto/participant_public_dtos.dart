class CreateParticipantPublicRequestDto {
  final String nom;
  final String? telephone;

  const CreateParticipantPublicRequestDto({required this.nom, this.telephone});

  Map<String, dynamic> toJson() => {
        'nom': nom,
        if (telephone != null && telephone!.isNotEmpty) 'telephone': telephone,
      };
}

class AssignArticleRequestDto {
  final String articleId;
  final double partMontant;

  const AssignArticleRequestDto({required this.articleId, required this.partMontant});

  Map<String, dynamic> toJson() => {'articleId': articleId, 'partMontant': partMontant};
}