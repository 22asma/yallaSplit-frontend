import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:yallasplit_app/core/config/api_endpoints.dart';
import 'package:yallasplit_app/core/errors/app_exception.dart';
import 'package:yallasplit_app/features/addition/data/dto/addition_update_dtos.dart';
import '../dto/addition_dtos.dart';
import '../modals/addition_model.dart';
import '../modals/scanned_receipt_model.dart';

class AdditionApiService {
  final Dio _dio;

  AdditionApiService(this._dio);

  Future<List<AdditionModel>> getAll() async {
    try {
      final response = await _dio.get(ApiEndpoints.additions);
      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => AdditionModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<AdditionModel> getById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.additionById(id));
      final data = response.data['data'] as Map<String, dynamic>;
      return AdditionModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Envoie la photo du reçu, reçoit les articles extraits par OCR (preview, ne crée rien en base).
  Future<ScannedReceiptModel> scanRecu(Uint8List imageBytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(imageBytes, filename: filename),
      });
      final response = await _dio.post(ApiEndpoints.scanRecu, data: formData);
      final data = response.data['data'] as Map<String, dynamic>;
      return ScannedReceiptModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Crée réellement l'addition en base, après validation des articles par l'hôte.
  Future<AdditionModel> create(CreateAdditionRequestDto dto) async {
    try {
      final response = await _dio.post(ApiEndpoints.additions, data: dto.toJson());
      final data = response.data['data'] as Map<String, dynamic>;
      return AdditionModel.fromJson(data);
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

  Future<AdditionModel> update(String id, UpdateAdditionRequestDto dto) async {
  try {
    final response = await _dio.patch(ApiEndpoints.updateAddition(id), data: dto.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    return AdditionModel.fromJson(data);
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<void> delete(String id) async {
  try {
    await _dio.delete(ApiEndpoints.deleteAddition(id));
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<void> addArticle(String additionId, CreateArticleUpdateDto dto) async {
  try {
    await _dio.post(ApiEndpoints.addArticleToAddition(additionId), data: dto.toJson());
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<void> updateArticle(String additionId, String articleId, CreateArticleUpdateDto dto) async {
  try {
    await _dio.patch(ApiEndpoints.updateArticleOfAddition(additionId, articleId), data: dto.toJson());
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<void> removeArticle(String additionId, String articleId) async {
  try {
    await _dio.delete(ApiEndpoints.deleteArticleOfAddition(additionId, articleId));
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}
}