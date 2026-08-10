import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';
import 'package:yallasplit_app/core/errors/app_exception.dart';
import 'package:yallasplit_app/features/addition/data/modals/participant_detail_model.dart';
import '../dto/participant_public_dtos.dart';
import '../modals/public_addition_model.dart';
import '../modals/repartition_model.dart';

class ParticipantPublicApiService {
  final Dio _dio;

  ParticipantPublicApiService(this._dio);

  Future<PublicAdditionModel> getAddition(String token) async {
    try {
      final response = await _dio.get(ApiEndpoints.lienPaiementPublic(token));
      final data = response.data['data'] as Map<String, dynamic>;
      return PublicAdditionModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<String> rejoindre(String token, CreateParticipantPublicRequestDto dto) async {
    try {
      final response = await _dio.post(ApiEndpoints.rejoindre(token), data: dto.toJson());
      final data = response.data['data'] as Map<String, dynamic>;
      return data['id'] as String;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<String> assignerArticle(String token, String participantId, AssignArticleRequestDto dto) async {
  try {
    final response = await _dio.post(ApiEndpoints.assignerArticle(token, participantId), data: dto.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    return data['id'] as String; // id de l'ArticleParticipant créé
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

  Future<void> supprimerAssignation(String token, String participantId, String articleParticipantId) async {
    try {
      await _dio.delete(ApiEndpoints.supprimerAssignation(token, participantId, articleParticipantId));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<RepartitionModel> calculerMontant(String token, String participantId) async {
    try {
      final response = await _dio.get(ApiEndpoints.calculerMontant(token, participantId));
      final data = response.data['data'] as Map<String, dynamic>;
      return RepartitionModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<String> payer(String token, String participantId) async {
    try {
      final response = await _dio.post(ApiEndpoints.payer(token, participantId));
      final data = response.data['data'] as Map<String, dynamic>;
      return data['checkoutUrl'] as String;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<RepartitionModel> confirmerPaiement(String token, String participantId, String sessionId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.confirmerPaiement(token, participantId),
        queryParameters: {'session_id': sessionId},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return RepartitionModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    if (e.response?.data != null) {
      return AppException.fromResponseData(e.response!.data, statusCode);
    }
    return AppException(
      code: 'NETWORK_ERROR',
      message: 'Impossible de contacter le serveur.',
      statusCode: 0,
    );
  }

  Future<ParticipantDetailModel> getParticipant(String token, String participantId) async {
  try {
    final response = await _dio.get(ApiEndpoints.getParticipantPublic(token, participantId));
    final data = response.data['data'] as Map<String, dynamic>;
    return ParticipantDetailModel.fromJson(data);
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<void> modifierAssignation(
  String token,
  String participantId,
  String articleParticipantId,
  double partMontant,
) async {
  try {
    await _dio.patch(
      ApiEndpoints.modifierAssignation(token, participantId, articleParticipantId),
      data: {'partMontant': partMontant},
    );
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<RepartitionModel> choisirTaxe(String token, String participantId) async {
  try {
    final response = await _dio.post(ApiEndpoints.choisirTaxe(token, participantId));
    final data = response.data['data'] as Map<String, dynamic>;
    return RepartitionModel.fromJson(data);
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<RepartitionModel> retirerTaxe(String token, String participantId) async {
  try {
    final response = await _dio.delete(ApiEndpoints.retirerTaxe(token, participantId));
    final data = response.data['data'] as Map<String, dynamic>;
    return RepartitionModel.fromJson(data);
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}
}