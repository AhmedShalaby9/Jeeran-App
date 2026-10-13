import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_api.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_view.dart';
import 'package:jeeran_flutter/features/voice/voice_api.dart';
import 'package:jeeran_flutter/features/voice/voice_page.dart';
import 'package:jeeran_flutter/features/voice/voice_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Recorder implements VoiceRecorder {
  bool allowed = true;
  String? file = '/tmp/voice.m4a';
  int started = 0;

  @override
  Future<bool> requestPermission() async => allowed;
  @override
  Future<void> start() async => started++;
  @override
  Future<String?> stop() async => file;
  @override
  Future<void> cancel() async {}
  @override
  void dispose() {}
}

class _Speaker implements VoiceSpeaker {
  final said = <String>[];
  @override
  Future<void> speak(
    String text,
    String lang, {
    void Function()? onDone,
  }) async {
    said.add(text);
    onDone?.call();
  }

  @override
  Future<void> stop() async {}
}

/// Stands in for the server: upload gives a transcript, chat gives an answer.
class _FakeClient extends ApiClient {
  String transcript = 'Chalets in Sahel under twelve million';
  bool fail = false;
  Map<String, dynamic>? uploaded;
  Map<String, dynamic>? sentMessage;

  Response _ok(String path, dynamic data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'success': true, 'data': data},
  );

  @override
  Future<Response> postMultipart(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? fields,
    DioMediaType? contentType,
  }) async {
    if (fail) throw Exception('down');
    uploaded = {'path': path, 'field': fileField, ...?fields};
    return _ok(path, {'id': 41, 'transcript': transcript, 'language': 'en'});
  }

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async => _ok(path, <dynamic>[]);

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    if (path == '/chat/sessions') return _ok(path, {'id': 9});
    sentMessage = data as Map<String, dynamic>;
    return _ok(path, {'reply': 'Six chalets match.', 'references': {}});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_voice_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('record, fix the text, ask, hear it — ${locale.languageCode}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final rec = _Recorder();
      final speaker = _Speaker();
      final client = _FakeClient();
      final host = ValueNotifier<Widget>(
        VoicePage(
          api: VoiceApi(client),
          recorder: rec,
          speaker: speaker,
          askApi: AskApi(client),
        ),
      );
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
              home: ValueListenableBuilder<Widget>(
                valueListenable: host,
                builder: (_, page, _) =>
                    KeyedSubtree(key: ObjectKey(page), child: page),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // nothing heard, then a server that is down: each ends in a way out
      client.transcript = '';
      host.value = VoicePage(
        api: VoiceApi(client),
        recorder: rec,
        speaker: speaker,
      );
      await tester.pump();
      Future<void> record() async {
        await tester.tap(find.byKey(const Key('voice-mic')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 2));
        await tester.tap(find.byKey(const Key('voice-mic')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await record();
      expect(find.text('voice.nospeech_title'.tr()), findsOneWidget);
      await tester.tap(find.text('voice.try_again'.tr()));
      await tester.pump();
      client.fail = true;
      await record();
      expect(find.text('voice.failed_title'.tr()), findsOneWidget);
      expect(find.text('voice.type_instead'.tr()), findsOneWidget);
      client.fail = false;
      client.transcript = 'Chalets in Sahel under twelve million';
      host.value = VoicePage(
        api: VoiceApi(client),
        recorder: rec,
        speaker: speaker,
        askApi: AskApi(client),
      );
      await tester.pump();

      // idle
      expect(find.text('voice.idle_title'.tr()), findsOneWidget);
      expect(tester.takeException(), isNull);

      // denied mic → notice with a way to settings, nothing recorded
      rec.started = 0;
      rec.allowed = false;
      await tester.tap(find.byKey(const Key('voice-mic')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('voice.denied_title'.tr()), findsOneWidget);
      expect(find.text('voice.open_settings'.tr()), findsOneWidget);
      expect(rec.started, 0);
      await tester.tap(find.byKey(const Key('voice-notice-primary')));
      await tester.pump();
      rec.allowed = true;

      // the language chip cycles auto → ar → en and is what the recording is sent as
      await tester.tap(find.byKey(const Key('voice-lang')));
      await tester.pump();
      expect(find.text('voice.lang_ar'.tr()), findsWidgets);

      // record 3 seconds: the live card is shown, then stop
      await tester.tap(find.byKey(const Key('voice-mic')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(rec.started, 1);
      expect(find.byKey(const Key('voice-live')), findsOneWidget);
      expect(find.text('voice.hearing'.tr().toUpperCase()), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byKey(const Key('voice-mic')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      // upload carried the audio field, the length and the chosen language
      expect(client.uploaded!['path'], '/voice/transcribe');
      expect(client.uploaded!['field'], 'audio');
      expect(client.uploaded!['duration'], greaterThanOrEqualTo(3));
      expect(client.uploaded!['language'], 'ar');

      // no confirm step: it searches straight away, on this screen, and reads the answer back
      expect(
        client.sentMessage!['content'],
        'Chalets in Sahel under twelve million',
      );
      expect(client.sentMessage!['voice_id'], 41);
      expect(speaker.said, ['Six chalets match.']);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('voice-reply')), findsOneWidget);
      expect(find.text('Six chalets match.'), findsOneWidget);
      // what was heard stays visible, with a way to fix it
      expect(
        find.text('Chalets in Sahel under twelve million'),
        findsOneWidget,
      );
      expect(find.byType(AskView), findsNothing);

      // fix the text and send it again
      await tester.tap(find.byKey(const Key('voice-edit')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('voice-text')),
        'Chalets in Sahel under 11 million',
      );
      await tester.tap(find.byKey(const Key('voice-send')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        client.sentMessage!['content'],
        'Chalets in Sahel under 11 million',
      );
      expect(client.sentMessage!.containsKey('voice_id'), isFalse);

      // continue in Ask → the same conversation opens in the chat
      await tester.tap(find.byKey(const Key('voice-continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AskView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
