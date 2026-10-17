import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/ai_chat/scoped/ask_context.dart';
import 'package:jeeran_flutter/features/ai_chat/scoped/ask_scope_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _prop(int id, String title) => {
  'id': id,
  'title_ar': title,
  'title_en': title,
  'price': 3400000,
  'size': 40,
  'images': <String>[],
  'project': {'id': 805, 'name_ar': 'أفيلين', 'name_en': 'Avelin'},
};

class _Api extends ApiClient {
  Response _ok(String p, dynamic b) =>
      Response(requestOptions: RequestOptions(path: p), statusCode: 200, data: b);

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async =>
      _ok(path, {
        'success': true,
        'data': {'name': 'Avelin', 'source': '12 units', 'prompts': <String>[], 'limit': {'limit': 30, 'remaining': 29}},
      });

  @override
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    if (path == '/chat/sessions') return _ok(path, {'success': true, 'data': {'id': 32}});
    return _ok(path, {
      'success': true,
      'data': {
        'reply': 'Two studios are available.',
        'references': {
          'properties': [_prop(1, 'Studio in Avelin'), _prop(2, 'Studio Plus')],
          'projects': [
            {'id': 805, 'name_ar': 'أفيلين', 'name_en': 'Avelin'},
          ],
          'facts': [
            {'label': 'Starting price', 'value': '3,400,000 EGP'},
          ],
        },
        'limit': {'limit': 30, 'remaining': 28},
      },
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_scoped_cards').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('the scoped chat shows the cards it read — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final host = ValueNotifier<Widget>(const SizedBox());
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
                builder: (_, w, _) => KeyedSubtree(key: ObjectKey(w), child: w),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));
      host.value = Scaffold(
        body: AskContextSheet(
          scope: const AskScope(AskScopeType.compound, 805, 'Avelin'),
          api: AskScopeApi(_Api()),
          firstQuestion: 'What is the cheapest unit here?',
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.text('Two studios are available.'), findsOneWidget);
      expect(find.textContaining('Studio in Avelin'), findsWidgets); // the unit rail
      expect(find.textContaining('Studio Plus'), findsWidgets);
      expect(find.text('3,400,000 EGP'), findsOneWidget); // the facts still show
      expect(tester.takeException(), isNull);
    });
  }
}
