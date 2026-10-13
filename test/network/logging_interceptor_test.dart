import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/core/network/interceptors/logging_interceptor.dart';

void main() {
  test('secrets are masked, long bodies cut, multipart summarised', () {
    final shown = LoggingInterceptor.show({
      'phone': '+2010',
      'password': 'hunter2',
      'otp': '123456',
      'nested': {'access_token': 'abc', 'ok': 1},
      'list': [
        {'code': '999'},
      ],
    });
    expect(shown, contains('+2010'));
    expect(shown, isNot(contains('hunter2')));
    expect(shown, isNot(contains('123456')));
    expect(shown, isNot(contains('abc')));
    expect(shown, isNot(contains('999')));
    expect('***'.allMatches(shown).length, 4);

    final long = LoggingInterceptor.show({'text': 'x' * 5000});
    expect(long.length, lessThan(1700));
    expect(long, contains('more chars').or(contains('chars)')));

    final form = FormData.fromMap({'duration': 7, 'audio': MultipartFile.fromBytes([1, 2], filename: 'a.m4a')});
    expect(LoggingInterceptor.show(form), allOf(contains('duration'), contains('audio'), isNot(contains('a.m4a'))));
  });

  test('a full round trip prints request, response and time, with the token hidden', () async {
    final lines = <String>[];
    LoggingInterceptor.sink = lines.add;
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..interceptors.add(LoggingInterceptor())
      ..httpClientAdapter = _Ok();
    await dio.post('/p', data: {'a': 1}, options: Options(headers: {'Authorization': 'Bearer secret-token'}));
    final all = lines.join('\n');
    expect(all, contains('→ POST http://x/p'));
    expect(all, contains('← 200 POST http://x/p'));
    expect(all, contains('"a":1'));
    expect(all, contains('"ok":true'));
    expect(all, isNot(contains('secret-token')));
  });
}

class _Ok implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString('{"ok":true}', 200, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });
}

extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
