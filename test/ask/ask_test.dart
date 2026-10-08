import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/error/exceptions.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_api.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _firstPara =
    'Six chalets match — three bedrooms, North Coast, delivered and under 12M EGP.';
const _tail =
    'Prices are from listings live today. Want me to narrow to lagoon-side only?';

Map<String, dynamic> _prop(int id, String title) => {
  'id': id,
  'title_ar': title,
  'title_en': title,
  'price': 11200000,
  'size': 171,
  'images': <String>[],
  'project': {'id': 4, 'name_ar': 'مراسي', 'name_en': 'Marassi'},
};

class _FakeApi extends ApiClient {
  final calls = <String>[];
  bool limited = false;
  List<Map<String, dynamic>> sessions = [
    {
      'id': 7,
      'title': 'Chalets in Sahel',
      'updated_at': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toUtc()
          .toIso8601String(),
      'summary': {'properties': 6, 'projects': 2, 'news': 0},
    },
    {
      'id': 8,
      'title': 'What is left on my plan?',
      'updated_at': DateTime.now()
          .subtract(const Duration(days: 3))
          .toUtc()
          .toIso8601String(),
      'summary': {'properties': 0, 'projects': 0, 'news': 0},
    },
  ];

  Response _ok(String path, dynamic body) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: body,
  );

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    calls.add('GET $path');
    if (path == '/chat/sessions')
      return _ok(path, {'success': true, 'data': sessions});
    if (path == '/chat/sessions/7/messages') {
      return _ok(path, {
        'success': true,
        'data': [
          {
            'id': 1,
            'role': 'user',
            'content': 'Chalets in Sahel',
            'references': null,
          },
          {
            'id': 2,
            'role': 'assistant',
            'content': 'Found two.',
            'references': {
              'properties': [_prop(1, 'Old chalet')],
              'projects': [],
              'news': [],
            },
          },
        ],
      });
    }
    return _ok(path, {'success': true, 'data': <dynamic>[]});
  }

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    calls.add('POST $path ${data ?? ''}');
    if (path == '/chat/sessions')
      return _ok(path, {
        'success': true,
        'data': {'id': 9},
      });
    if (path.endsWith('/messages')) {
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      ); // the model takes a moment
      if (limited) throw const ServerException('limit', 'ai_limit', 1200);
      return _ok(path, {
        'success': true,
        'data': {
          'reply': '$_firstPara\n\n$_tail',
          'references': {
            'properties': [
              _prop(1, 'Garden chalet'),
              _prop(2, 'Lagoon chalet'),
            ],
            'projects': [
              {
                'id': 4,
                'name_ar': 'مراسي',
                'name_en': 'Marassi',
                'developer': {'name_en': 'Emaar Misr', 'name_ar': 'إعمار'},
              },
            ],
            'news': [
              {
                'id': 3,
                'title_en': 'Phase 4 released',
                'title_ar': 'طرح المرحلة 4',
              },
            ],
            'facts': [
              {'label': 'Cheapest', 'value': '11.2M'},
            ],
          },
        },
      });
    }
    return _ok(path, {'success': true});
  }

  @override
  Future<Response> delete(String path) async {
    calls.add('DELETE $path');
    return _ok(path, {'success': true});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('data', () {
    test('references: counts, facts and an empty case', () {
      final r = AskRefs.fromJson({
        'properties': [_prop(1, 'a')],
        'projects': [
          {'id': 2},
        ],
        'news': [],
        'facts': [
          {'label': 'x', 'value': 'y'},
          {'label': '', 'value': 'z'},
        ],
      });
      expect(r.properties, hasLength(1));
      expect(r.facts, [('x', 'y')]); // a row without a label is dropped
      expect(AskRefs.fromJson(null).isEmpty, isTrue);
    });

    test('a history row carries what its last answer read', () {
      final row = AskSessionRow.fromJson({
        'id': 1,
        'title': 't',
        'updated_at': '2026-10-01T10:00:00Z',
        'summary': {'properties': 6, 'projects': 2, 'news': 1},
      });
      expect((row.listings, row.compounds, row.news), (6, 2, 1));
    });
  });

  group('screens', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_ask_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      final lang = locale.languageCode;
      testWidgets(
        'Ask in $lang: prompts → thinking → typed answer with cards → history',
        (tester) async {
          tester.view.physicalSize = const Size(390 * 3, 2200 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          final api = _FakeApi();
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
                  home: AskView(api: AskApi(api)),
                ),
              ),
            ),
          );
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);

          // empty state: four starter prompts (a buyer sees the buyer one, not the plan question)
          expect(find.text('concierge.p1'.tr()), findsOneWidget);
          expect(find.text('concierge.p4_buyer'.tr()), findsOneWidget);
          expect(find.text('concierge.p4_seller'.tr()), findsNothing);

          // asking creates the chat once, shows the working step, then types the answer out
          await tester.tap(find.text('concierge.p1'.tr()));
          await tester.pump(const Duration(milliseconds: 20));
          expect(find.text('concierge.step'.tr()), findsOneWidget);
          await tester.pump(
            const Duration(milliseconds: 400),
          ); // the answer arrives and starts typing
          // mid-typing: the cards have not landed yet
          expect(find.textContaining('Facts'), findsNothing);
          expect(find.text('Garden chalet'), findsNothing);
          await tester.pump(const Duration(seconds: 3));
          expect(
            api.calls.where((c) => c.startsWith('POST /chat/sessions ')).length,
            1,
          );
          expect(find.textContaining('Six chalets match'), findsOneWidget);

          // …then the sources line, the cards, the numbers behind it, and the closing paragraph
          expect(
            find.text(
              'concierge.s_listings'.plural(2) +
                  ' · ' +
                  'concierge.s_compounds'.plural(1) +
                  ' · ' +
                  'concierge.s_news'.plural(1),
            ),
            findsOneWidget,
          );
          expect(find.text('Garden chalet'), findsOneWidget);
          expect(find.text('Lagoon chalet'), findsOneWidget);
          expect(find.text(lang == 'ar' ? 'مراسي' : 'Marassi'), findsWidgets);
          expect(
            find.text(lang == 'ar' ? 'طرح المرحلة 4' : 'Phase 4 released'),
            findsOneWidget,
          );
          expect(find.text('Cheapest'), findsOneWidget);
          expect(find.textContaining('Want me to narrow'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // a second question reuses the same chat
          await tester.enterText(find.byType(TextField), 'and in Sharm?');
          await tester.testTextInput.receiveAction(TextInputAction.send);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(seconds: 4));
          expect(
            api.calls.where((c) => c.startsWith('POST /chat/sessions ')).length,
            1,
          );
          expect(
            api.calls
                .where((c) => c.contains('/chat/sessions/9/messages'))
                .length,
            2,
          );

          // the hourly limit gets a plain message with the wait
          api.limited = true;
          await tester.enterText(find.byType(TextField), 'once more');
          await tester.testTextInput.receiveAction(TextInputAction.send);
          await tester.pump(const Duration(milliseconds: 800));
          expect(find.text('concierge.limit'.tr(args: ['20'])), findsOneWidget);
          api.limited = false;

          // history: summaries, open one, delete one
          await tester.tap(find.byIcon(Icons.history_rounded));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Chalets in Sahel'), findsOneWidget);
          expect(
            find.textContaining('concierge.s_listings'.plural(6)),
            findsOneWidget,
          );
          expect(
            find.textContaining('concierge.meta_account'.tr()),
            findsOneWidget,
          ); // no references → "account"
          await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
          await tester.pump(const Duration(milliseconds: 300));
          expect(api.calls, contains('DELETE /chat/sessions/8'));
          expect(find.text('What is left on my plan?'), findsNothing);
          await tester.tap(find.text('Chalets in Sahel'));
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pump(const Duration(milliseconds: 600));
          expect(api.calls, contains('GET /chat/sessions/7/messages'));
          expect(find.text('Found two.'), findsOneWidget);
          expect(find.text('Old chalet'), findsOneWidget);

          // a new chat goes back to the prompts
          await tester.tap(find.byIcon(Icons.add_rounded));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('concierge.p1'.tr()), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
