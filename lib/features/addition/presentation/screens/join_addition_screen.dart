import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yallasplit_app/core/config/app_theme.dart';
import 'package:yallasplit_app/core/widgets/gradient_button.dart';
import 'package:yallasplit_app/core/widgets/app_text_field.dart';
import '../../data/modals/public_addition_model.dart';
import '../providers/addition_providers.dart';
import '../providers/join_addition_notifier.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class JoinAdditionScreen extends ConsumerWidget {
  final String token;

  const JoinAdditionScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(joinAdditionProvider(token));

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: switch (state.status) {
          JoinStatus.loading =>
            const Center(child: CircularProgressIndicator(color: AppColors.violet)),
          JoinStatus.error => _ErrorView(message: state.errorMessage ?? 'Erreur'),
          JoinStatus.notJoined => _JoinForm(token: token),
          JoinStatus.joined => _ItemsSelectionView(token: token, state: state),
        },
      ),
    );
  }
}

class _JoinForm extends ConsumerStatefulWidget {
  final String token;
  const _JoinForm({required this.token});

  @override
  ConsumerState<_JoinForm> createState() => _JoinFormState();
}

class _JoinFormState extends ConsumerState<_JoinForm> {
  final _nomController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addition = ref.watch(joinAdditionProvider(widget.token)).addition;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Everyone pays their share', style: AppTextStyles.display.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          if (addition != null)
            Text('Total : AED ${addition.montantTotal.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMuted),
          const SizedBox(height: 32),
          AppTextField(
            controller: _nomController,
            label: 'TON NOM',
            hint: 'Karim Ben Salah',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Rejoindre',
            isLoading: _loading,
            onPressed: () async {
              if (_nomController.text.trim().isEmpty) return;
              setState(() => _loading = true);
              await ref
                  .read(joinAdditionProvider(widget.token).notifier)
                  .rejoindre(_nomController.text.trim(), null);
              if (mounted) setState(() => _loading = false);
            },
          ),
        ],
      ),
    );
  }
}

class _ItemsSelectionView extends ConsumerWidget {
  final String token;
  final JoinAdditionState state;

  const _ItemsSelectionView({required this.token, required this.state});

  /// Combien d'unités de cet article CE participant a déjà prises,
  /// déduit depuis partMontant / prix unitaire.
  int _monQuantitePriseSur(PublicArticleModel article) {
    final assignment = article.prisPar.where((p) => p.participantId == state.participantId);
    if (assignment.isEmpty) return 0;
    final montantMoi = assignment.first.partMontant;
    return article.prix > 0 ? (montantMoi / article.prix).round() : 0;
  }

  Widget _buildTaxeRow(BuildContext context, WidgetRef ref) {
    final addition = state.addition!;
    if (addition.taxe <= 0) return const SizedBox.shrink();

    final taxePayeur = addition.taxePayeur;
    final priseParMoi = taxePayeur?.participantId == state.participantId;
    final priseParAutrui = taxePayeur != null && !priseParMoi;
    final dejaPayeGlobal = state.repartition?.statut == 'PAYE';
    final isLocked = dejaPayeGlobal || priseParAutrui || (taxePayeur?.paye ?? false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: priseParMoi ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: priseParMoi ? Border.all(color: AppColors.gold) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TVA / Taxe', style: AppTextStyles.body),
                  if (priseParAutrui)
                    Text(
                      taxePayeur!.paye
                          ? 'Payée par ${taxePayeur.nom}'
                          : 'Prise par ${taxePayeur.nom}',
                      style: AppTextStyles.caption.copyWith(
                        color: taxePayeur.paye ? AppColors.moneyGreen : AppColors.gold,
                      ),
                    ),
                ],
              ),
            ),
            Text('AED ${addition.taxe.toStringAsFixed(2)}', style: AppTextStyles.body),
            const SizedBox(width: 12),
            Checkbox(
              value: priseParMoi,
              activeColor: AppColors.gold,
              onChanged: isLocked
                  ? null
                  : (_) => ref.read(joinAdditionProvider(token).notifier).toggleTaxe(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addition = state.addition!;
    final dejaPaye = state.repartition?.statut == 'PAYE';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Who had what?', style: AppTextStyles.h1),
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.errorMessage!,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              ),
            ),
          ),
        if (dejaPaye)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.moneyGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.moneyGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tu as déjà payé ta part',
                    style: AppTextStyles.caption.copyWith(color: AppColors.moneyGreen),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildTaxeRow(context, ref),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () => ref.read(joinAdditionProvider(token).notifier).refreshAll(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: addition.articles.length,
              itemBuilder: (context, index) {
                final article = addition.articles[index];
                final selectedByMe = state.selectedArticles.containsKey(article.id);
                final isPending = state.pendingArticleIds.contains(article.id);
                final maQuantite = _monQuantitePriseSur(article);

                final articlePaye = article.dejaPaye;
                final isMultiple = article.quantite > 1;

                final isLockedSimple = !isMultiple &&
                    ((article.entierementAssigne && !selectedByMe) || articlePaye);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selectedByMe || maQuantite > 0
                        ? AppColors.violet.withValues(alpha: 0.15)
                        : (isLockedSimple
                            ? AppColors.surface.withValues(alpha: 0.5)
                            : AppColors.surface),
                    borderRadius: BorderRadius.circular(14),
                    border: (selectedByMe || maQuantite > 0)
                        ? Border.all(color: AppColors.violet)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMultiple ? '${article.nom} ×${article.quantite}' : article.nom,
                              style: AppTextStyles.body.copyWith(
                                color: isLockedSimple ? AppColors.muted : AppColors.text,
                              ),
                            ),
                            if (isMultiple && article.montantDejaAssigne > 0)
                              Text(
                                article.entierementAssigne
                                    ? 'Entièrement pris'
                                    : '${article.prisPar.length} personne(s) ont déjà pris une part',
                                style: AppTextStyles.caption.copyWith(
                                  color: article.entierementAssigne
                                      ? AppColors.moneyGreen
                                      : AppColors.gold,
                                ),
                              )
                            else if (!isMultiple && article.prisPar.isNotEmpty && !selectedByMe)
                              Text(
                                articlePaye
                                    ? 'Payé par ${article.prisPar.first.nom}'
                                    : 'Pris par ${article.prisPar.first.nom}',
                                style: AppTextStyles.caption.copyWith(
                                  color: articlePaye ? AppColors.moneyGreen : AppColors.gold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'AED ${article.montantTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.body.copyWith(
                          color: isLockedSimple ? AppColors.muted : AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isPending)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.violet),
                        )
                      else if (isMultiple)
                        _QuantityStepper(
                          value: maQuantite,
                          max: article.quantite,
                          montantRestant: article.montantRestant,
                          prixUnitaire: article.prix,
                          disabled: dejaPaye,
                          onChanged: (q) => ref
                              .read(joinAdditionProvider(token).notifier)
                              .setArticleQuantity(article.id, q, article.prix),
                        )
                      else
                        Checkbox(
                          value: selectedByMe,
                          activeColor: AppColors.violet,
                          onChanged: (dejaPaye || isLockedSimple)
                              ? null
                              : (_) => ref
                                  .read(joinAdditionProvider(token).notifier)
                                  .toggleArticle(article.id, article.prix, article.quantite),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Container(
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
                  Text('Ta part', style: AppTextStyles.h2),
                  Text(
                    'AED ${(state.repartition?.montant ?? 0).toStringAsFixed(2)}',
                    style: AppTextStyles.display.copyWith(fontSize: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!dejaPaye)
                GradientButton(
                  label: 'Payer ma part',
                  onPressed: state.repartition == null || state.repartition!.montant <= 0
                      ? null
                      : () async {
                          final url = await ref
                              .read(joinAdditionProvider(token).notifier)
                              .demarrerPaiement();
                          if (url != null) {
                            await launchUrl(
                              Uri.parse(url),
                              mode: kIsWeb
                                  ? LaunchMode.platformDefault
                                  : LaunchMode.inAppBrowserView,
                            );
                          }
                        },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int value;
  final int max;
  final double montantRestant;
  final double prixUnitaire;
  final bool disabled;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({
    required this.value,
    required this.max,
    required this.montantRestant,
    required this.prixUnitaire,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uniteMax = prixUnitaire > 0
        ? ((montantRestant / prixUnitaire).floor() + value).clamp(0, max)
        : max;

    final canDecrement = !disabled && value > 0;
    final canIncrement = !disabled && value < uniteMax;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          color: canDecrement ? AppColors.violet : AppColors.muted,
          onPressed: canDecrement ? () => onChanged(value - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(
          width: 28,
          child: Text('$value', textAlign: TextAlign.center, style: AppTextStyles.body),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: canIncrement ? AppColors.violet : AppColors.muted,
          onPressed: canIncrement ? () => onChanged(value + 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}