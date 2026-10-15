import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../error/exceptions.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 35),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  /// Sent by the v2 screens (compound / developer pages): the API answers in
  /// the new vocabulary — `compound` instead of `project`.
  static const apiV2 = {'X-Api-Version': '2'};

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParams,
        options: headers == null ? null : Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: headers == null ? null : Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// For calls that legitimately take a minute (image generation).
  Future<Response> postLong(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: Options(headers: headers, receiveTimeout: const Duration(seconds: 120)),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> putWithHeaders(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    try {
      return await _dio.put(
        path,
        data: data,
        options: headers == null ? null : Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        options: headers == null ? null : Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> postMultipart(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? fields,
    DioMediaType? contentType,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?fields,
        fileField: await MultipartFile.fromFile(
          filePath,
          contentType: contentType,
        ),
      });
      return await _dio.post(
        path,
        data: formData,
        queryParameters: queryParams,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException();
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badResponse:
        final message = _extractErrorMessage(e.response);
        return switch (e.response?.statusCode) {
          401 => UnauthorizedException(),
          404 => NotFoundException(),
          _ => ServerException(message, _extractCode(e.response), _extractRetry(e.response)),
        };
      default:
        return ServerException();
    }
  }

  String? _extractCode(Response? response) {
    final data = response?.data;
    return data is Map<String, dynamic> && data['code'] is String ? data['code'] as String : null;
  }

  int? _extractRetry(Response? response) {
    final data = response?.data;
    final inner = data is Map<String, dynamic> ? data['data'] : null;
    final v = inner is Map<String, dynamic> ? inner['retry_after_seconds'] : null;
    return v is num ? v.toInt() : null;
  }

  String? _extractErrorMessage(Response? response) {
    final data = response?.data;
    if (data == null) return null;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['chat'] ?? data['error'] ?? data['msg'];
      if (msg is String && msg.isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) {
        return msg.whereType<String>().join('\n');
      }
    }
    return null;
  }
}
