import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug builds only: every call with its request, response and time, in the console.
/// Tokens, passwords and one-time codes print as `***`; long bodies are cut.
class LoggingInterceptor extends Interceptor {
  static final _secret = RegExp(
    r'^(authorization|password|token|access_token|refresh_token|id_token|fcm_token|otp|code|session_info|recaptcha_token|secret|api_key)$',
    caseSensitive: false,
  );
  static const _max = 1500;
  static const _startKey = '_log_started_at';

  /// Where lines go (the console by default; tests capture them).
  @visibleForTesting
  static void Function(String) sink = debugPrint;

  static dynamic redact(dynamic v, [int depth = 0]) {
    if (depth > 6) return v;
    if (v is Map) {
      return {
        for (final e in v.entries)
          '${e.key}': _secret.hasMatch('${e.key}') ? '***' : redact(e.value, depth + 1),
      };
    }
    if (v is List) return v.take(20).map((e) => redact(e, depth + 1)).toList();
    return v;
  }

  static String show(dynamic body) {
    if (body == null) return '';
    String text;
    if (body is FormData) {
      text =
          'multipart ${body.fields.map((f) => f.key).toList()} files ${body.files.map((f) => f.key).toList()}';
    } else {
      try {
        text = jsonEncode(redact(body));
      } catch (_) {
        text = '$body';
      }
    }
    return text.length > _max ? '${text.substring(0, _max)}… (+${text.length - _max} chars)' : text;
  }

  String _took(RequestOptions o) {
    final started = o.extra[_startKey];
    if (started is! int) return '';
    return ' ${DateTime.now().millisecondsSinceEpoch - started}ms';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
      final h = redact(options.headers);
      sink('→ ${options.method} ${options.uri}');
      sink('    headers ${jsonEncode(h)}');
      if (options.data != null) sink('    body    ${show(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final o = response.requestOptions;
      sink('← ${response.statusCode} ${o.method} ${o.uri}${_took(o)}');
      sink('    body    ${show(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final o = err.requestOptions;
      sink('✗ ${err.response?.statusCode ?? err.type.name} ${o.method} ${o.uri}${_took(o)}: ${err.message}');
      if (err.response?.data != null) sink('    body    ${show(err.response?.data)}');
    }
    handler.next(err);
  }
}
