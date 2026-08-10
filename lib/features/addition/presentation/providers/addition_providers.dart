import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yallasplit_app/features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/addition_api_service.dart';
import '../../data/modals/addition_model.dart';
import 'scan_receipt_notifier.dart';
import '../../data/datasources/lien_paiement_api_service.dart';
import '../../data/modals/lien_paiement_model.dart';
import '../../data/modals/participant_model.dart';
import 'package:yallasplit_app/core/network/public_dio_client.dart';
import '../../data/datasources/participant_public_api_service.dart';
import 'join_addition_notifier.dart';


final additionApiServiceProvider = Provider<AdditionApiService>((ref) {
  return AdditionApiService(ref.watch(dioClientProvider));
});

final additionsListProvider = FutureProvider.autoDispose<List<AdditionModel>>((ref) async {
  final api = ref.watch(additionApiServiceProvider);
  return api.getAll();
});

final scanReceiptProvider =
    StateNotifierProvider.autoDispose<ScanReceiptNotifier, ScanReceiptState>((ref) {
  return ScanReceiptNotifier(ref.watch(additionApiServiceProvider));
});

final lienPaiementApiServiceProvider = Provider<LienPaiementApiService>((ref) {
  return LienPaiementApiService(ref.watch(dioClientProvider));
});

final lienPaiementProvider =
    FutureProvider.autoDispose.family<LienPaiementModel, String>((ref, additionId) async {
  final api = ref.watch(lienPaiementApiServiceProvider);
  return api.genererOuRecuperer(additionId);
});

final participantsProvider =
    FutureProvider.autoDispose.family<List<ParticipantModel>, String>((ref, additionId) async {
  final api = ref.watch(lienPaiementApiServiceProvider);
  return api.getParticipants(additionId);
});

final publicDioProvider = Provider<Dio>((ref) => PublicDioClient().dio);

final participantPublicApiServiceProvider = Provider<ParticipantPublicApiService>((ref) {
  return ParticipantPublicApiService(ref.watch(publicDioProvider));
});

final joinAdditionProvider = StateNotifierProvider.autoDispose
    .family<JoinAdditionNotifier, JoinAdditionState, String>((ref, token) {
  return JoinAdditionNotifier(ref.watch(participantPublicApiServiceProvider), token);
});

final additionDetailProvider =
    FutureProvider.autoDispose.family<AdditionModel, String>((ref, id) async {
  final api = ref.watch(additionApiServiceProvider);
  return api.getById(id);
});