import '../modals/scanned_receipt_model.dart';

class CreateArticleRequestDto {
  final String nom;
  final double prix;
  final int quantite;

  const CreateArticleRequestDto({
    required this.nom,
    required this.prix,
    required this.quantite,
  });

  factory CreateArticleRequestDto.fromScanned(ScannedArticle a) {
    return CreateArticleRequestDto(nom: a.nom, prix: a.prix, quantite: a.quantite);
  }

  Map<String, dynamic> toJson() => {'nom': nom, 'prix': prix, 'quantite': quantite};
}

class CreateAdditionRequestDto {
  final double montantTotal;
  final double taxe;
  final String? imageRecuUrl;
  final List<CreateArticleRequestDto> articles;

  const CreateAdditionRequestDto({
    required this.montantTotal,
    required this.taxe,
    this.imageRecuUrl,
    required this.articles,
  });

  Map<String, dynamic> toJson() => {
        'montantTotal': montantTotal,
        'taxe': taxe,
        if (imageRecuUrl != null) 'imageRecuUrl': imageRecuUrl,
        'articles': articles.map((a) => a.toJson()).toList(),
      };
}