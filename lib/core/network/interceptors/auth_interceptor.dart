import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../navigation/app_navigator.dart';
import '../../storage/app_storage.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';

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
      Sentry.addBreadcrumb(Breadcrumb(
        message: '401 → forced logout',
        category: 'auth',
        level: SentryLevel.warning,
        data: {'url': err.requestOptions.uri.toString()},
      ));
      AppStorage.clearAuth();
      _redirectToLogin();
    }
    handler.next(err);
  }

  void _redirectToLogin() {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    // Pop all routes and push login so the user can't go back to an authenticated screen.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
