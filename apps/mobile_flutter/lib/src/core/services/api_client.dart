import 'dart:math';

import 'package:dio/dio.dart';

import '../models/app_models.dart';
import 'app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class DealDropApiClient {
  DealDropApiClient({
    required AppConfig config,
    required Future<AuthSessionModel?> Function() sessionReader,
  })  : _sessionReader = sessionReader,
        _dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
            sendTimeout: const Duration(seconds: 12),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio _dio;
  final Future<AuthSessionModel?> Function() _sessionReader;
  final Random _random = Random();

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () async => _dio.get<Map<String, dynamic>>(
            path,
            queryParameters: queryParameters,
            options: await _options(authenticated: authenticated),
          ),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) async {
    final response = await _request<List<dynamic>>(
      () async => _dio.get<List<dynamic>>(
            path,
            queryParameters: queryParameters,
            options: await _options(authenticated: authenticated),
          ),
    );
    return response.data ?? const [];
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    bool idempotent = false,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () async => _dio.post<Map<String, dynamic>>(
            path,
            data: body,
            queryParameters: queryParameters,
            options: await _options(authenticated: authenticated, idempotent: idempotent),
          ),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> postNoContent(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    bool idempotent = false,
  }) async {
    await _request<void>(
      () async => _dio.post<void>(
            path,
            data: body,
            options: await _options(authenticated: authenticated, idempotent: idempotent),
          ),
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = false,
  }) async {
    final response = await _request<Map<String, dynamic>>(
      () async => _dio.put<Map<String, dynamic>>(
            path,
            data: body,
            options: await _options(authenticated: authenticated),
          ),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    await _request<void>(
      () async => _dio.delete<void>(
            path,
            data: body,
            options: await _options(authenticated: authenticated),
          ),
    );
  }

  Future<Response<T>> _request<T>(Future<Response<T>> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      final message = switch (error.type) {
        DioExceptionType.connectionTimeout => 'Connection timed out.',
        DioExceptionType.receiveTimeout => 'Server response timed out.',
        DioExceptionType.connectionError => 'No network connection available.',
        _ => _extractErrorMessage(error),
      };
      throw ApiException(message, statusCode: error.response?.statusCode);
    }
  }

  Future<Options> _options({
    required bool authenticated,
    bool idempotent = false,
  }) async {
    final headers = <String, dynamic>{};
    if (authenticated) {
      final session = await _sessionReader();
      if (session == null) {
        throw const ApiException('Sign in is required.', statusCode: 401);
      }
      headers.addAll({
        'x-dev-user-id': session.userId,
        'x-dev-email': session.email,
        'x-dev-role': session.role,
        'x-dev-name': session.displayName,
        'x-dev-verified-contributor': '${session.verifiedContributor}',
      });
    }
    if (idempotent) {
      headers['Idempotency-Key'] = _idempotencyKey();
    }
    return Options(headers: headers);
  }

  String _idempotencyKey() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final salt = _random.nextInt(1 << 31);
    return 'mobile-$timestamp-$salt';
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? (data['error'] as String?) ?? 'Request failed.';
    }
    return error.message ?? 'Request failed.';
  }
}
