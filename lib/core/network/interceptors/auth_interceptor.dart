import 'package:dio/dio.dart';
import '../../storage/app_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = AppStorage.authToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final lang = AppStorage.language ?? 'en';
    options.headers['Accept-Language'] = lang;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      AppStorage.clearAuth();
    }
    handler.next(err);
  }
}
