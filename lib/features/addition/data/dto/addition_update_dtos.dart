class UpdateAdditionRequestDto {
  final double? montantTotal;
  final double? taxe;
  final String? statut;

  const UpdateAdditionRequestDto({this.montantTotal, this.taxe, this.statut});

  Map<String, dynamic> toJson() => {
        if (montantTotal != null) 'montantTotal': montantTotal,
        if (taxe != null) 'taxe': taxe,
        if (statut != null) 'statut': statut,
      };
}

class CreateArticleUpdateDto {
  final String nom;
  final double prix;
  final int quantite;

  const CreateArticleUpdateDto({required this.nom, required this.prix, required this.quantite});

  Map<String, dynamic> toJson() => {'nom': nom, 'prix': prix, 'quantite': quantite};
}