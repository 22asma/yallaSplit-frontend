import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import '../../data/dto/addition_update_dtos.dart';
import '../../data/modals/addition_model.dart';
import '../../data/modals/article_model.dart';
import '../../data/modals/participant_model.dart';
import '../providers/addition_providers.dart';

class AdditionDetailScreen extends ConsumerWidget {
  final String additionId;

  const AdditionDetailScreen({super.key, required this.additionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final additionAsync = ref.watch(additionDetailProvider(additionId));
    final participantsAsync = ref.watch(participantsProvider(additionId));

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: additionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
          error: (e, _) => Center(child: Text('$e', style: AppTextStyles.bodyMuted)),
          data: (addition) => RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async {
              ref.invalidate(additionDetailProvider(additionId));
              ref.invalidate(participantsProvider(additionId));
              ref.invalidate(lienPaiementProvider(additionId));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTopBar(context, ref, addition),
                const SizedBox(height: 20),
                _buildSummaryCard(addition),
                const SizedBox(height: 20),
                _buildLinkSection(context, ref),
                const SizedBox(height: 24),
                _buildArticlesSection(context, ref, addition),
                const SizedBox(height: 24),
                _buildParticipantsSection(participantsAsync),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, AdditionModel addition) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            ref.invalidate(additionsListProvider);
            context.pop();
          },
        ),
        Expanded(
          child: Text('Détail de l\'addition', style: AppTextStyles.h1),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.muted),
          onPressed: () {
            ref.invalidate(additionDetailProvider(additionId));
            ref.invalidate(participantsProvider(additionId));
            ref.invalidate(lienPaiementProvider(additionId));
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.muted),
          onPressed: () => _showEditAdditionDialog(context, ref, addition),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () => _confirmDeleteAddition(context, ref),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(AdditionModel addition) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.caption),
              _StatusBadge(statut: addition.statut),
            ],
          ),
          const SizedBox(height: 6),
          Text('AED ${addition.montantTotal.toStringAsFixed(2)}',
              style: AppTextStyles.display.copyWith(fontSize: 28)),
          const SizedBox(height: 8),
          Text('Taxe : AED ${addition.taxe.toStringAsFixed(2)}', style: AppTextStyles.bodyMuted),
          Text('${addition.articles.length} articles', style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }

  Widget _buildLinkSection(BuildContext context, WidgetRef ref) {
    final lienAsync = ref.watch(lienPaiementProvider(additionId));

    return lienAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(color: AppColors.violet, strokeWidth: 2)),
      ),
      error: (e, _) => Text('Lien indisponible', style: AppTextStyles.bodyMuted),
      data: (lien) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LIEN DE PAIEMENT', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lien.urlSecurisee.replaceFirst(RegExp(r'^https?://'), ''),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.muted),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: lien.urlSecurisee));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lien copié')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code, size: 18, color: AppColors.muted),
                  onPressed: () => _showQrDialog(context, lien.urlSecurisee),
                ),
                IconButton(
                  icon: const Icon(Icons.chat, size: 18, color: AppColors.whatsapp),
                  onPressed: () async {
                    final message = Uri.encodeComponent(
                      'Paye ta part sur YallaSplit : ${lien.urlSecurisee}',
                    );
                    final uri = Uri.parse('https://wa.me/?text=$message');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scanne pour payer', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: url, version: QrVersions.auto, size: 220),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer', style: AppTextStyles.body.copyWith(color: AppColors.violet)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesSection(BuildContext context, WidgetRef ref, AdditionModel addition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Articles', style: AppTextStyles.h2),
            TextButton.icon(
              onPressed: () => _showArticleDialog(context, ref, addition),
              icon: const Icon(Icons.add, color: AppColors.violet, size: 18),
              label: Text('Ajouter', style: AppTextStyles.body.copyWith(color: AppColors.violet)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...addition.articles.map(
          (article) => _ArticleRow(
            article: article,
            onEdit: () => _showArticleDialog(context, ref, addition, existing: article),
            onDelete: () => _confirmDeleteArticle(context, ref, addition.id, article),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection(AsyncValue<List<ParticipantModel>> participantsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Participants', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        participantsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppColors.violet)),
          ),
          error: (e, _) => Text('$e', style: AppTextStyles.bodyMuted),
          data: (participants) => participants.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, color: AppColors.muted, size: 32),
                      const SizedBox(height: 10),
                      Text('Personne n\'a encore rejoint', style: AppTextStyles.bodyMuted),
                    ],
                  ),
                )
              : Column(
                  children: participants.map((p) => _ParticipantRow(participant: p)).toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _showEditAdditionDialog(BuildContext context, WidgetRef ref, AdditionModel addition) async {
    final montantController = TextEditingController(text: addition.montantTotal.toStringAsFixed(2));
    final taxeController = TextEditingController(text: addition.taxe.toStringAsFixed(2));

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Modifier l\'addition', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montantController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body,
              decoration: const InputDecoration(labelText: 'Montant total'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: taxeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body,
              decoration: const InputDecoration(labelText: 'Taxe'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Enregistrer', style: AppTextStyles.body.copyWith(color: AppColors.violet)),
          ),
        ],
      ),
    );

    if (saved == true) {
      final api = ref.read(additionApiServiceProvider);
      try {
        await api.update(
          addition.id,
          UpdateAdditionRequestDto(
            montantTotal: double.tryParse(montantController.text),
            taxe: double.tryParse(taxeController.text),
          ),
        );
        ref.invalidate(additionDetailProvider(addition.id));
        ref.invalidate(additionsListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Future<void> _confirmDeleteAddition(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Supprimer cette addition ?', style: AppTextStyles.h2),
        content: Text('Cette action est irréversible.', style: AppTextStyles.bodyMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(additionApiServiceProvider);
      try {
        await api.delete(additionId);
        ref.invalidate(additionsListProvider);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Future<void> _showArticleDialog(
    BuildContext context,
    WidgetRef ref,
    AdditionModel addition, {
    ArticleModel? existing,
  }) async {
    final nomController = TextEditingController(text: existing?.nom ?? '');
    final prixController = TextEditingController(
      text: existing != null ? existing.prix.toStringAsFixed(2) : '',
    );
    final quantiteController = TextEditingController(
      text: (existing?.quantite ?? 1).toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(existing == null ? 'Ajouter un article' : 'Modifier l\'article',
            style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              style: AppTextStyles.body,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prixController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body,
              decoration: const InputDecoration(labelText: 'Prix unitaire'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantiteController,
              keyboardType: TextInputType.number,
              style: AppTextStyles.body,
              decoration: const InputDecoration(labelText: 'Quantité'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Enregistrer', style: AppTextStyles.body.copyWith(color: AppColors.violet)),
          ),
        ],
      ),
    );

    if (saved == true) {
      final api = ref.read(additionApiServiceProvider);
      final dto = CreateArticleUpdateDto(
        nom: nomController.text.trim(),
        prix: double.tryParse(prixController.text) ?? 0,
        quantite: int.tryParse(quantiteController.text) ?? 1,
      );
      try {
        if (existing == null) {
          await api.addArticle(addition.id, dto);
        } else {
          await api.updateArticle(addition.id, existing.id, dto);
        }
        ref.invalidate(additionDetailProvider(addition.id));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Future<void> _confirmDeleteArticle(
    BuildContext context,
    WidgetRef ref,
    String additionId,
    ArticleModel article,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Supprimer "${article.nom}" ?', style: AppTextStyles.h2),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(additionApiServiceProvider);
      try {
        await api.removeArticle(additionId, article.id);
        ref.invalidate(additionDetailProvider(additionId));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final StatutAddition statut;
  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (statut) {
      case StatutAddition.cloturee:
        color = AppColors.moneyGreen;
        label = 'Settled';
        break;
      case StatutAddition.annulee:
        color = AppColors.danger;
        label = 'Cancelled';
        break;
      case StatutAddition.brouillon:
        color = AppColors.muted;
        label = 'Draft';
        break;
      default:
        color = AppColors.gold;
        label = 'Collecting';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ArticleRow({required this.article, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.nom, style: AppTextStyles.body),
                if (article.quantite > 1)
                  Text('×${article.quantite}', style: AppTextStyles.caption),
              ],
            ),
          ),
          Text('AED ${article.prix.toStringAsFixed(2)}', style: AppTextStyles.body),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final ParticipantModel participant;
  const _ParticipantRow({required this.participant});

  @override
  Widget build(BuildContext context) {
    final paye = participant.aPaye;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.violet,
            child: Text(
              participant.nom.isNotEmpty ? participant.nom[0].toUpperCase() : '?',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participant.nom, style: AppTextStyles.body),
                if (participant.montant != null)
                  Text('AED ${participant.montant!.toStringAsFixed(2)}', style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (paye ? AppColors.moneyGreen : AppColors.gold).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              paye ? 'Paid' : 'Pending',
              style: AppTextStyles.caption.copyWith(color: paye ? AppColors.moneyGreen : AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}