import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yallasplit_app/core/errors/app_exception.dart';
import '../../data/datasources/participant_public_api_service.dart';
import '../../data/dto/participant_public_dtos.dart';
import '../../data/modals/public_addition_model.dart';
import '../../data/modals/repartition_model.dart';

enum JoinStatus { loading, notJoined, joined, error }

class JoinAdditionState {
  final JoinStatus status;
  final PublicAdditionModel? addition;
  final String? participantId;
  // articleId -> articleParticipantId (nécessaire pour DELETE/PATCH, et pour
  // savoir ce que CE participant a déjà pris)
  final Map<String, String> selectedArticles;
  // Verrou anti double-tap pendant qu'une requête est en cours pour un article donné.
  final Set<String> pendingArticleIds;
  final RepartitionModel? repartition;
  final String? errorMessage;

  const JoinAdditionState({
    this.status = JoinStatus.loading,
    this.addition,
    this.participantId,
    this.selectedArticles = const {},
    this.pendingArticleIds = const {},
    this.repartition,
    this.errorMessage,
  });

  JoinAdditionState copyWith({
    JoinStatus? status,
    PublicAdditionModel? addition,
    String? participantId,
    Map<String, String>? selectedArticles,
    Set<String>? pendingArticleIds,
    RepartitionModel? repartition,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JoinAdditionState(
      status: status ?? this.status,
      addition: addition ?? this.addition,
      participantId: participantId ?? this.participantId,
      selectedArticles: selectedArticles ?? this.selectedArticles,
      pendingArticleIds: pendingArticleIds ?? this.pendingArticleIds,
      repartition: repartition ?? this.repartition,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class JoinAdditionNotifier extends StateNotifier<JoinAdditionState> {
  final ParticipantPublicApiService _api;
  final String token;

  JoinAdditionNotifier(this._api, this.token) : super(const JoinAdditionState()) {
    _loadAddition();
  }

  Future<void> _loadAddition() async {
    state = state.copyWith(status: JoinStatus.loading, clearError: true);
    try {
      final addition = await _api.getAddition(token);
      final savedParticipantId = await _getSavedParticipantId();

      state = state.copyWith(
        addition: addition,
        participantId: savedParticipantId,
        status: savedParticipantId != null ? JoinStatus.joined : JoinStatus.notJoined,
      );

      if (savedParticipantId != null) {
        await _hydrateSelections(savedParticipantId);
        await _recalculer();
      }
    } on AppException catch (e) {
      state = state.copyWith(status: JoinStatus.error, errorMessage: e.message);
    }
  }

  /// Recharge depuis le backend les articles déjà choisis par CE participant,
  /// pour ne pas les proposer comme "libres" après un refresh de la page.
  Future<void> _hydrateSelections(String participantId) async {
    try {
      final detail = await _api.getParticipant(token, participantId);
      final map = <String, String>{
        for (final a in detail.articleParticipants) a.articleId: a.id,
      };
      state = state.copyWith(selectedArticles: map);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: 'Impossible de recharger tes choix : ${e.message}');
    }
  }

  Future<bool> rejoindre(String nom, String? telephone) async {
    state = state.copyWith(status: JoinStatus.loading, clearError: true);
    try {
      final participantId = await _api.rejoindre(
        token,
        CreateParticipantPublicRequestDto(nom: nom, telephone: telephone),
      );
      await _saveParticipantId(participantId);
      state = state.copyWith(status: JoinStatus.joined, participantId: participantId);
      await _loadAddition();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(status: JoinStatus.notJoined, errorMessage: e.message);
      return false;
    }
  }

  /// Utilisé pour les articles à quantité 1 (simple checkbox) : bascule
  /// entre "je prends tout" et "je ne prends rien".
  Future<void> toggleArticle(String articleId, double prixUnitaire, int quantite) async {
    final alreadySelected = state.selectedArticles.containsKey(articleId);
    await setArticleQuantity(articleId, alreadySelected ? 0 : quantite, prixUnitaire);
  }

  /// Utilisé pour les articles à quantité > 1 (stepper) : fixe directement
  /// le nombre d'unités que CE participant prend à sa charge.
  Future<void> setArticleQuantity(String articleId, int quantitePrise, double prixUnitaire) async {
    if (state.participantId == null) return;
    if (state.pendingArticleIds.contains(articleId)) return;

    final currentAssignmentId = state.selectedArticles[articleId];
    state = state.copyWith(pendingArticleIds: {...state.pendingArticleIds, articleId});

    try {
      if (quantitePrise <= 0) {
        // Retire complètement l'assignation si on repasse à 0.
        if (currentAssignmentId != null) {
          await _api.supprimerAssignation(token, state.participantId!, currentAssignmentId);
          final updated = {...state.selectedArticles}..remove(articleId);
          state = state.copyWith(selectedArticles: updated);
        }
      } else {
        final partMontant = prixUnitaire * quantitePrise;
        if (currentAssignmentId != null) {
          await _api.modifierAssignation(token, state.participantId!, currentAssignmentId, partMontant);
        } else {
          final newId = await _api.assignerArticle(
            token,
            state.participantId!,
            AssignArticleRequestDto(articleId: articleId, partMontant: partMontant),
          );
          final updated = {...state.selectedArticles, articleId: newId};
          state = state.copyWith(selectedArticles: updated);
        }
      }
      await _recalculer();
      await _refreshAdditionSilently();
    } on AppException catch (e) {
      // Cas typique : conflit si un autre participant a pris entre-temps
      // les unités restantes -> on resynchronise depuis le serveur.
      state = state.copyWith(errorMessage: e.message);
      await _hydrateSelections(state.participantId!);
      await _refreshAdditionSilently();
    } finally {
      final updatedPending = {...state.pendingArticleIds}..remove(articleId);
      state = state.copyWith(pendingArticleIds: updatedPending);
    }
  }

  /// Recharge l'addition (montants déjà pris par tous les participants) sans
  /// passer par le status "loading" global, pour éviter que l'écran clignote
  /// à chaque action.
  Future<void> _refreshAdditionSilently() async {
    try {
      final addition = await _api.getAddition(token);
      state = state.copyWith(addition: addition);
    } catch (_) {
      // Non bloquant : pas critique si ça échoue ponctuellement.
    }
  }

  Future<void> _recalculer() async {
    if (state.participantId == null) return;
    try {
      final repartition = await _api.calculerMontant(token, state.participantId!);
      state = state.copyWith(repartition: repartition);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<String?> demarrerPaiement() async {
    if (state.participantId == null) return null;
    try {
      final checkoutUrl = await _api.payer(token, state.participantId!);
      return checkoutUrl;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    }
  }

  /// Recharge tout depuis le serveur (pull-to-refresh) : utile pour voir
  /// les paiements/sélections des autres participants faits entre-temps.
  Future<void> refreshAll() async {
    await _loadAddition();
  }

  Future<void> _saveParticipantId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('participant_id_$token', id);
  }

  Future<String?> _getSavedParticipantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('participant_id_$token');
  }

  Future<void> toggleTaxe() async {
  if (state.participantId == null || state.addition == null) return;
  final dejaChoisie = state.addition!.taxePayeur?.participantId == state.participantId;

  try {
    if (dejaChoisie) {
      await _api.retirerTaxe(token, state.participantId!);
    } else {
      await _api.choisirTaxe(token, state.participantId!);
    }
    await _recalculer();
    await _refreshAdditionSilently();
  } on AppException catch (e) {
    state = state.copyWith(errorMessage: e.message);
  }
}
}