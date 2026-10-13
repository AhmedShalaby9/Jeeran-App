import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/explore/presentation/pages/all_compounds_page.dart';
import 'package:jeeran_flutter/features/search/data/search_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _c(int id, String en, String dev, String area) => {
  'id': id,
  'name_ar': en,
  'name_en': en,
  'gallery': [],
  'features': [],
  'is_active': true,
  'min_price': 9800000,
  'units_count': 14,
  'developer': {'id': 1, 'name_ar': dev, 'name_en': dev},
  'area': {'name_ar': area, 'name_en': area},
};

class _Fake extends ApiClient {
  final calls = <Map<String, dynamic>>[];

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    Response ok(dynamic body) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: body,
    );
    if (path == '/areas') {
      return ok({
        'success': true,
        'data': [
          {
            'id': 3,
            'name_ar': 'الساحل',
            'name_en': 'North Coast',
            'listing_count': 9,
          },
        ],
      });
    }
    final q = queryParams ?? {};
    calls.add(q);
    final all = [
      _c(1, 'Marassi', 'Emaar Misr', 'North Coast'),
      _c(2, 'Madinaty', 'TMG', 'New Cairo'),
    ];
    final items = all.where((c) {
      final text = '${c['name_en']} ${(c['developer'] as Map)['name_en']}'
          .toLowerCase();
      final area = (c['area'] as Map)['name_en'];
      return (q['q'] == null || text.contains('${q['q']}'.toLowerCase())) &&
          (q['area_id'] == null || area == 'North Coast');
    }).toList();
    return ok({'success': true, 'data': items, 'total': items.length});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_allc_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'all compounds: search, area and rows in ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final api = _Fake();
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
                home: AllCompoundsPage(api: SearchApi(api)),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('compound-row-1')), findsOneWidget);
        expect(find.byKey(const Key('compound-row-2')), findsOneWidget);
        expect(find.byKey(const Key('area-3')), findsOneWidget);

        // narrowing by area asks the server for that area only
        await tester.tap(find.byKey(const Key('area-3')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(api.calls.last['area_id'], 3);
        expect(find.byKey(const Key('compound-row-2')), findsNothing);

        // searching by a developer's name
        await tester.tap(find.byKey(const Key('area-all')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byKey(const Key('compound-q')), 'tmg');
        await tester.pump(const Duration(milliseconds: 300));
        expect(api.calls.last['q'], 'tmg');
        expect(find.byKey(const Key('compound-row-2')), findsOneWidget);
        expect(find.byKey(const Key('compound-row-1')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
