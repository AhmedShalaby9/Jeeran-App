import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/di/injection_container.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_api.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Quiet extends ApiClient {
  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async =>
      Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: {'success': true, 'data': <String, dynamic>{}});
}

// What the chat sends back when a seller says "I want to list my 3-bedroom chalet in Marassi, ready, 165 m²".
final _refs = AskRefs.fromJson({
  'listing': {
    'draft': {'type': 'chalet', 'status': 'for_sale', 'compound_id': 4, 'bedrooms': 3, 'size': 165, 'delivery': 'ready'},
    'compound': {'id': 4, 'name_ar': 'مراسي', 'name_en': 'Marassi', 'developer_en': 'Emaar Misr', 'developer_ar': 'إعمار'},
    'filled': ['type', 'compound_id', 'bedrooms', 'size', 'delivery'],
    'missing': ['price', 'payment'],
    'complete': false,
    'question': "What's the asking price?",
    'replies': <String>[],
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_ask_listing').path);
    await Hive.openBox('jeeran_prefs');
    if (!sl.isRegistered<ApiClient>()) sl.registerSingleton<ApiClient>(_Quiet());
  });

  test('the listing the assistant started is read from the reference', () {
    expect(_refs.listing, isNotNull);
    expect(_refs.listing!.missing, ['price', 'payment']);
    expect(_refs.listing!.compound!.nameEn, 'Marassi');
    expect(AskRefs.fromJson({'properties': <dynamic>[]}).listing, isNull);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('a chat answer shows the listing table and carries on in Tell Jeeran — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
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
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AskAssistantMsg(
                      text: 'Got it.',
                      tail: '',
                      refs: _refs,
                      typing: false,
                      saidAbout: 'I want to list my 3-bedroom chalet in Marassi',
                      onProperty: (_) {},
                      onCompound: (_, _) {},
                      onNews: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // the table: what was understood ticked, what is missing marked Needed
      expect(find.byKey(const Key('listing-card')), findsOneWidget);
      expect(find.byKey(const Key('listing-row-sale_type')), findsOneWidget);
      expect(find.byKey(const Key('listing-row-price')), findsOneWidget);
      expect(find.text('listing.needed'.tr()), findsNWidgets(3)); // price, payment, photos
      expect(find.text('165 m²'), findsOneWidget);

      // continue: the full screen opens with the same table and the next question
      await tester.tap(find.byKey(const Key('listing-continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('action-card')), findsOneWidget);
      expect(find.text('I want to list my 3-bedroom chalet in Marassi'), findsOneWidget);
      expect(find.textContaining("What's the asking price?"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
