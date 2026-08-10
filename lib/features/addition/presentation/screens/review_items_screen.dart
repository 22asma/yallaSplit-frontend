import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/core/widgets/gradient_button.dart';
import '../../data/modals/scanned_receipt_model.dart';
import '../providers/addition_providers.dart';
import '../providers/scan_receipt_notifier.dart';

class ReviewItemsScreen extends ConsumerWidget {
  const ReviewItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanReceiptProvider);

    if (state.receipt == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun reçu scanné')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildRestaurantCard(),
                  const SizedBox(height: 20),
                  ...state.editableArticles.asMap().entries.map(
                        (entry) => _ArticleTile(
                          key: ValueKey(entry.key),
                          index: entry.key,
                          article: entry.value,
                          ref: ref,
                        ),
                      ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => ref.read(scanReceiptProvider.notifier).addEmptyArticle(),
                    icon: const Icon(Icons.add, color: AppColors.violet, size: 18),
                    label: Text('Add an item',
                        style: AppTextStyles.body.copyWith(color: AppColors.violet)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildBottomBar(context, ref, state),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.violet, size: 14),
                  const SizedBox(width: 4),
                  Text('Smart Scan', style: AppTextStyles.caption.copyWith(color: AppColors.violet)),
                ],
              ),
              Text('Review items', style: AppTextStyles.h1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard() {
    // Note : le nom du restaurant n'est pas encore un champ du modèle
    // Addition côté backend — pour l'instant purement informatif dans l'UI.
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RESTAURANT', style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Text('Reçu scanné', style: AppTextStyles.body),
            ],
          ),
          Text('Edit', style: AppTextStyles.caption.copyWith(color: AppColors.blue)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, ScanReceiptState state) {
    final isCreating = state.status == ScanStatus.creating;
    final sousTotal =
        state.editableArticles.fold(0.0, (sum, a) => sum + (a.prix * a.quantite));
    final taxe = state.receipt?.taxe ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.base,
        border: Border(top: BorderSide(color: AppColors.surface)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sous-total articles', style: AppTextStyles.bodyMuted),
              Text('AED ${sousTotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMuted),
            ],
          ),
          if (taxe > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('dont TVA / Taxe (incluse)', style: AppTextStyles.bodyMuted),
                Text('AED ${taxe.toStringAsFixed(2)}', style: AppTextStyles.bodyMuted),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.h2),
              // state.total = receipt.montantTotal (déjà TTC), pas un recalcul.
              Text('AED ${state.total.toStringAsFixed(2)}',
                  style: AppTextStyles.display.copyWith(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Claim your items →',
            isLoading: isCreating,
            onPressed: () async {
              final ok = await ref.read(scanReceiptProvider.notifier).confirmAndCreate();
              if (!context.mounted) return;

              if (ok) {
                final addition = ref.read(scanReceiptProvider).createdAddition;
                ref.invalidate(additionsListProvider);

                if (addition != null) {
                  context.go(
                    '/addition/${addition.id}/share?montant=${addition.montantTotal}',
                  );
                } else {
                  // Filet de sécurité : ne devrait pas arriver si ok == true.
                  context.go('/home');
                }
              } else {
                final error = ref.read(scanReceiptProvider).errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? "Échec de la création de l'addition")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ArticleTile extends StatefulWidget {
  final int index;
  final ScannedArticle article;
  final WidgetRef ref;

  const _ArticleTile({
    super.key,
    required this.index,
    required this.article,
    required this.ref,
  });

  @override
  State<_ArticleTile> createState() => _ArticleTileState();
}

class _ArticleTileState extends State<_ArticleTile> {
  late final TextEditingController _nomController;
  late final TextEditingController _prixController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.article.nom);
    _prixController = TextEditingController(
      text: widget.article.prix == 0 ? '' : widget.article.prix.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  void _onNomChanged(String value) {
    widget.ref.read(scanReceiptProvider.notifier).updateArticle(
          widget.index,
          widget.article.copyWith(nom: value),
        );
  }

  void _onPrixChanged(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    widget.ref.read(scanReceiptProvider.notifier).updateArticle(
          widget.index,
          widget.article.copyWith(prix: parsed),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nomController,
              onChanged: _onNomChanged,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Nom de l\'article',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _prixController,
              onChanged: _onPrixChanged,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
            onPressed: () => widget.ref.read(scanReceiptProvider.notifier).removeArticle(widget.index),
          ),
        ],
      ),
    );
  }
}