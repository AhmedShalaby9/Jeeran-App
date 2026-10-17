import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/ai_chat/scoped/ask_context.dart';
import 'package:jeeran_flutter/features/ai_chat/scoped/ask_scope_api.dart';
import 'package:jeeran_flutter/features/voice/voice_api.dart';
import 'package:jeeran_flutter/features/voice/voice_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Recorder implements VoiceRecorder {
  bool allowed = true;
  int started = 0, cancelled = 0;

  @override
  Future<bool> requestPermission() async => allowed;
  @override
  Future<void> start() async => started++;
  @override
  Future<String?> stop() async => '/tmp/voice.m4a';
  @override
  Future<void> cancel() async => cancelled++;
  @override
  void dispose() {}
}

class _Client extends ApiClient {
  int uploads = 0;
  Map<String, dynamic>? sent;

  Response _ok(String path, dynamic data) => Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: {'success': true, 'data': data});

  @override
  Future<Response> postMultipart(String path, {required String filePath, String fileField = 'file', Map<String, dynamic>? queryParams, Map<String, dynamic>? fields, DioMediaType? contentType}) async {
    uploads++;
    return _ok(path, {'id': 77, 'transcript': 'Chalets in Sahel under twelve million'});
  }

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async =>
      _ok(path, {'name': 'Avelin', 'source': '12 units', 'prompts': <String>[], 'limit': {'limit': 30, 'remaining': 29}});

  @override
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    if (path == '/chat/sessions') return _ok(path, {'id': 9});
    sent = data as Map<String, dynamic>;
    return _ok(path, {'reply': 'Six chalets match.', 'references': {}});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_scoped_voice_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('record a voice note in a compound/developer/property chat — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final rec = _Recorder();
      final client = _Client();
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: locale,
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: AskContextSheet(
                  scope: const AskScope(AskScopeType.compound, 805, 'Avelin'),
                  api: AskScopeApi(client),
                  voiceApi: VoiceApi(client),
                  recorder: rec,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }

      await settle();
      expect(find.byKey(const Key('ask-mic')), findsOneWidget);

      // cancel: back to the text box, nothing uploaded
      await tester.tap(find.byKey(const Key('ask-mic')));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('ask-recording')), findsOneWidget);
      expect(find.text('0:02'), findsOneWidget);
      await tester.tap(find.byKey(const Key('voice-cancel')));
      await settle();
      expect(find.byKey(const Key('ask-recording')), findsNothing);
      expect(find.byKey(const Key('ask-mic')), findsOneWidget);
      expect(rec.cancelled, 1);
      expect(client.uploads, 0);

      // send: transcribed, then asked like a typed message (with the recording's id)
      await tester.tap(find.byKey(const Key('ask-mic')));
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(const Key('voice-send')));
      await settle();
      expect(client.uploads, 1);
      expect(client.sent!['content'], 'Chalets in Sahel under twelve million');
      expect(client.sent!['voice_id'], 77);
      expect(find.text('Chalets in Sahel under twelve million'), findsWidgets);
      expect(find.text('Six chalets match.'), findsOneWidget);
      expect(find.byKey(const Key('ask-recording')), findsNothing);
      expect(find.byKey(const Key('ask-mic')), findsOneWidget);

      // no microphone permission: no recorder, a notice instead
      rec.allowed = false;
      final started = rec.started;
      await tester.tap(find.byKey(const Key('ask-mic')));
      await settle();
      expect(rec.started, started);
      expect(find.byKey(const Key('ask-recording')), findsNothing);
      expect(find.text('voice.denied_sub'.tr()), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
