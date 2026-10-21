import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_brief_page.dart';
import 'package:jeeran_flutter/features/voice/voice_api.dart';
import 'package:jeeran_flutter/features/voice/voice_services.dart';

import 'ad_studio_support.dart';

class _Recorder implements VoiceRecorder {
  bool allowed = true;
  int started = 0, cancelled = 0;
  @override
  Future<bool> requestPermission() async => allowed;
  @override
  Future<void> start() async => started++;
  @override
  Future<String?> stop() async => '/tmp/note.m4a';
  @override
  Future<void> cancel() async => cancelled++;
  @override
  void dispose() {}
}

class _Client extends ApiClient {
  final heard = <String>['Push the ready chalets for summer, keep it calm', 'and mention the lagoon view'];
  final sent = <Map<String, dynamic>>[];

  @override
  Future<Response> postMultipart(String path, {required String filePath, String fileField = 'file', Map<String, dynamic>? queryParams, Map<String, dynamic>? fields, DioMediaType? contentType}) async {
    sent.add({'path': path, ...?fields});
    return Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: {'success': true, 'data': {'id': sent.length, 'transcript': heard[sent.length - 1]}});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpAdStudioTests);

  testWidgets('the summary can be dictated: record, transcribe, and a second note continues the first', (t) async {
    t.view.physicalSize = const Size(390 * 3, 1400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final rec = _Recorder()..allowed = false;
    final client = _Client();
    await showPage(t, AdBriefPage(recorder: rec, voiceApi: VoiceApi(client), loadDevelopers: () async => const []));
    await settle(t);
    String summary() => (t.widget(find.byKey(const Key('ad-summary'))) as TextField).controller!.text;

    // microphone off: nothing is recorded, the admin is told why
    await t.tap(find.byKey(const Key('ad-mic')));
    await settle(t);
    expect(rec.started, 0);
    expect(find.textContaining("needs mic access"), findsOneWidget);
    rec.allowed = true;

    // first note
    await t.tap(find.byKey(const Key('ad-mic')));
    await t.pump();
    expect(rec.started, 1);
    await t.pump(const Duration(seconds: 3)); // the clock runs
    expect(find.textContaining('Listening'), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-mic'))); // stop → transcribe
    await settle(t);
    expect(client.sent.single['path'], '/voice/transcribe');
    expect(client.sent.single['duration'], greaterThanOrEqualTo(2));
    expect(summary(), 'Push the ready chalets for summer, keep it calm');
    expect(find.text('Write a summary to continue'), findsNothing); // the summary counts: Continue is enabled

    // a second note is added after the first, not instead of it
    await t.tap(find.byKey(const Key('ad-mic')));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    await t.tap(find.byKey(const Key('ad-mic')));
    await settle(t);
    expect(summary(), 'Push the ready chalets for summer, keep it calm and mention the lagoon view');
  });
}
