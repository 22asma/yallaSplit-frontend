class AppException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const AppException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  /// Parse le format backend: { error: { code, message, statusCode } }
  factory AppException.fromResponseData(dynamic data, int fallbackStatusCode) {
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final error = data['error'] as Map<String, dynamic>;
      return AppException(
        code: error['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error['message'] as String? ?? 'Une erreur est survenue',
        statusCode: error['statusCode'] as int? ?? fallbackStatusCode,
      );
    }
    return AppException(
      code: 'UNKNOWN_ERROR',
      message: 'Une erreur est survenue',
      statusCode: fallbackStatusCode,
    );
  }

  @override
  String toString() => 'AppException($code): $message';
}