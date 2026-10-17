import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/search/data/search_api.dart';
import 'package:jeeran_flutter/features/search/presentation/launches_page.dart';
import 'package:jeeran_flutter/features/search/presentation/promotion_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _promo(int id, String type, {List<Map<String, dynamic>> units = const []}) => {
  'id': id,
  'type': type,
  'title_en': type == 'launch' ? 'Marina Rise' : '5% down payment',
  'title_ar': type == 'launch' ? 'مارينا رايز' : 'مقدم 5%',
  'sub_en': 'From the developer',
  'sub_ar': 'من المطور',
  'compound_id': 5,
  'compound': {
    'id': 5,
    'name_en': 'Marassi',
    'name_ar': 'مراسي',
    'min_price': 11900000,
    'developer': {'name_en': 'Emaar Misr', 'name_ar': 'إعمار'},
  },
  'ends_at': DateTime.now().add(const Duration(days: 5)).toUtc().toIso8601String(),
  'video_url': null,
  'properties_count': units.length,
  'properties_min_price': units.isEmpty ? null : 11900000,
  'properties': units,
};

Map<String, dynamic> _unit(int id) => {
  'id': id,
  'title_en': 'Chalet $id',
  'title_ar': 'شاليه $id',
  'price': '11900000.00',
  'size': '120',
  'bedrooms': 2,
  'property_type': 'chalet',
  'images': <String>[],
};

class _Api extends ApiClient {
  Response _ok(String p, dynamic b) => Response(requestOptions: RequestOptions(path: p), statusCode: 200, data: {'success': true, 'data': b});

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async {
    if (path == '/promotions/1') return _ok(path, _promo(1, 'launch', units: [_unit(11), _unit(12)]));
    if (path == '/promotions/2') return _ok(path, _promo(2, 'offer'));
    if (path == '/promotions') return _ok(path, [_promo(1, 'launch', units: [_unit(11), _unit(12)]), _promo(2, 'offer')]);
    return _ok(path, <dynamic>[]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_promo_page').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('a launch or offer opens its own page — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final ar = locale.languageCode == 'ar';
      final api = SearchApi(_Api());
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
              home: Builder(
                builder: (ctx) => LaunchesPage(
                  api: api,
                  onOpen: (p) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => PromotionPage(item: p, api: api))),
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
      // tap the launch in the list → its page, not the search
      await tester.tap(find.text(ar ? 'مارينا رايز' : 'Marina Rise').first);
      await settle();
      await settle();
      expect(find.byKey(const Key('promotion-page')), findsOneWidget);
      expect(find.byKey(const Key('promo-title')), findsOneWidget);
      expect(find.byKey(const Key('promo-from')), findsOneWidget);
      expect(find.byKey(const Key('promo-ends')), findsOneWidget);
      expect(find.text('promo.view_compound'.tr()), findsOneWidget);
      expect(find.byKey(const Key('promo-units-title')), findsOneWidget);
      expect(find.byKey(const Key('unit-card-11')), findsOneWidget);
      expect(find.byKey(const Key('unit-card-12')), findsOneWidget);

      // back to the list, then an offer that covers the whole compound
      await tester.tap(find.byKey(const Key('promo-back')));
      await settle();
      await tester.tap(find.text(ar ? 'مقدم 5%' : '5% down payment').first);
      await settle();
      await settle();
      expect(find.byKey(const Key('promotion-page')), findsOneWidget);
      expect(find.byKey(const Key('promo-whole-compound')), findsOneWidget);
      expect(find.byKey(const Key('promo-units-title')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
