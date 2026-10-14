import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/search/data/search_api.dart';
import 'package:jeeran_flutter/features/search/presentation/offers_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _unit(int id, {bool offer = true, bool launch = false, double? pct}) => {
  'id': id,
  'title_ar': 'وحدة $id',
  'title_en': 'Apartment unit $id',
  'property_type': 'apartment',
  'price': '15900000.00',
  'size': '117.00',
  'bedrooms': 2,
  'bathrooms': 2,
  'images': <String>[],
  'has_offer': offer,
  'is_launch': launch,
  'offer_discount_percent': pct == null ? null : '$pct',
};

class _Api extends ApiClient {
  final calls = <Map<String, dynamic>>[];

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async {
    Response ok(dynamic body) => Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: body);
    if (path == '/properties') {
      calls.add({...?queryParams});
      final launchOnly = queryParams?['launch'] == '1' && queryParams?['offer'] == null;
      final items = launchOnly ? [_unit(3, offer: false, launch: true)] : [_unit(1, pct: 35), _unit(2)];
      return ok({
        'success': true,
        'data': items,
        'pagination': {'page': 1, 'limit': 20, 'total': launchOnly ? 91 : 881, 'pages': 1},
      });
    }
    return ok({'success': true, 'data': {}});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_offers_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final ar = locale.languageCode == 'ar';

    testWidgets('the offers list narrows by chips — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final api = _Api();
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
              home: OffersPage(api: SearchApi(api)),
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
      expect(tester.takeException(), isNull);
      // opens on Offer: the offer filter is on, both units show, with the total in the header
      expect(api.calls.first['offer'], '1');
      expect(find.byKey(const Key('unit-card-1')), findsOneWidget);
      expect(find.byKey(const Key('unit-card-2')), findsOneWidget);
      expect(find.text('find.n_units_total'.tr(namedArgs: {'n': '881'})), findsOneWidget);
      expect(find.text(ar ? 'عرض − 35٪' : 'Offer − 35%'), findsOneWidget);

      // Biggest discount sorts by the discount, highest first
      await tester.tap(find.byKey(const Key('chip-discount')));
      await settle();
      expect(api.calls.last['sort'], 'offer_discount_percent');
      expect(api.calls.last['order'], 'DESC');

      // turning Offer off and Launch on shows the launch units only
      await tester.tap(find.byKey(const Key('chip-offer')));
      await settle();
      await tester.tap(find.byKey(const Key('chip-launch')));
      await settle();
      expect(api.calls.last['launch'], '1');
      expect(api.calls.last['offer'], isNull);
      expect(find.byKey(const Key('unit-card-3')), findsOneWidget);
      expect(find.byKey(const Key('unit-card-1')), findsNothing);

      // Delivery opens a small sheet; "By 2028" reaches the server as every year up to it
      await tester.drag(find.byType(Scrollable).first, Offset(ar ? 400 : -400, 0)); // the chip row is wider than the screen
      await settle();
      await tester.tap(find.byKey(const Key('chip-delivery')));
      await settle();
      await tester.tap(find.byKey(const Key('pick-2028')));
      await settle();
      expect(api.calls.last['delivery'], 'ready,2026,2027,2028');
      expect(tester.takeException(), isNull);
    });
  }
}
