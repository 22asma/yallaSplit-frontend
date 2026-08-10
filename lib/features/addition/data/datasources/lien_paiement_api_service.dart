import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';
import 'package:yallasplit_app/core/errors/app_exception.dart';
import '../modals/lien_paiement_model.dart';
import '../modals/participant_model.dart';

class LienPaiementApiService {
  final Dio _dio;

  LienPaiementApiService(this._dio);

  Future<LienPaiementModel> genererOuRecuperer(String additionId) async {
    try {
      final response = await _dio.post(ApiEndpoints.lienPaiement(additionId));
      final data = response.data['data'] as Map<String, dynamic>;
      return LienPaiementModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<ParticipantModel>> getParticipants(String additionId) async {
    try {
      final response = await _dio.get(ApiEndpoints.participants(additionId));
      final data = response.data['data'] as List<dynamic>;
      return data.map((j) => ParticipantModel.fromJson(j as Map<String, dynamic>)).toList();
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
}