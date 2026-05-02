import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _baseUrl = 'https://deal-drop-y0qs.onrender.com';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  late final Dio _dio;

  /// Attach a JWT so subsequent requests include Authorization: Bearer <token>.
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }
}
