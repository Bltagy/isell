import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _tokenKey = 'auth_token';

/// Global locale code — updated by LocaleNotifier whenever language changes.
/// Used by ApiClient to send Accept-Language header.
String globalLocaleCode = 'ar';

class ApiClient {
  static Dio create({
    required String baseUrl,
    FlutterSecureStorage? secureStorage,
  }) {
    final storage = secureStorage ?? const FlutterSecureStorage();

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(storage),
      _LocaleInterceptor(),
      _ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ),
    ]);

    return dio;
  }
}

/// Attaches Accept-Language header to every request based on current locale.
class _LocaleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = globalLocaleCode;
    handler.next(options);
  }
}

/// Reads the Sanctum token from secure storage and attaches it to every request.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Normalises Dio errors into [ApiException] for consistent handling.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (response != null) {
      final message = _extractMessage(response.data) ??
          'Request failed with status ${response.statusCode}';
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: response,
          error: ApiException(
            message: message,
            statusCode: response.statusCode,
          ),
          type: err.type,
        ),
      );
      return;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const ApiException(message: 'Connection timed out'),
          type: err.type,
        ),
      );
      return;
    }

    if (err.type == DioExceptionType.connectionError) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const ApiException(message: 'No internet connection'),
          type: err.type,
        ),
      );
      return;
    }

    handler.next(err);
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
