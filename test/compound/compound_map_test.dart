import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/services/app_settings_service.dart';
import 'package:jeeran_flutter/features/compounds/data/compound_page_data.dart';
import 'package:jeeran_flutter/features/compounds/presentation/pages/compound_map_page.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _json(int id, String name, {bool plan = false}) => {
  'id': id,
  'name_en': name,
  'name_ar': name,
  'latitude': '30.0096590',
  'longitude': '31.5724640',
  'area': {'name_en': 'New Cairo', 'name_ar': 'القاهرة الجديدة'},
  'boundary': {
    'type': 'Polygon',
    'coordinates': [
      [
        [31.56, 30.0],
        [31.58, 30.0],
        [31.58, 30.02],
        [31.56, 30.02],
        [31.56, 30.0],
      ],
    ],
  },
  if (plan) 'plan_overlay_url': 'https://x/plan.png',
  if (plan) 'plan_bounds': [31.5508032, 29.994266, 31.5953279, 30.0272842],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_map_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  test('the outline and the plan position are read from the compound', () {
    final d = CompoundPageData.fromJson(_json(644, 'City Gate', plan: true));
    expect(d.boundary.single.length, 5);
    expect(d.boundary.single.first, [31.56, 30.0]); // [lng, lat]
    expect(d.planUrl, 'https://x/plan.png');
    expect(d.planBounds, [31.5508032, 29.994266, 31.5953279, 30.0272842]);
    final none = CompoundPageData.fromJson({'id': 1, 'boundary': null, 'plan_bounds': [1, 2]});
    expect(none.boundary, isEmpty);
    expect(none.planBounds, isNull); // a malformed position is ignored, not drawn wrong
    final multi = CompoundPageData.fromJson({
      'id': 2,
      'boundary': {
        'type': 'MultiPolygon',
        'coordinates': [
          [[[1, 1], [2, 1], [2, 2], [1, 1]]],
          [[[5, 5], [6, 5], [6, 6], [5, 5]]],
        ],
      },
    });
    expect(multi.boundary.length, 2);
  });

  testWidgets('the map shows the outline, the plan, neighbours; tapping a neighbour switches; contact buttons', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    AppSettingsService.instance.settings = AppSettings.fromJson({'contact_phone': '+201001112233'});
    addTearDown(() => AppSettingsService.instance.settings = null);

    final opened = <(String, String)>[];
    final asked = <int>[];
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: CompoundMapPage(
              compound: CompoundPageData.fromJson(_json(644, 'City Gate', plan: true)),
              showTiles: false,
              loadPins: (_) async => [
                MapPin(644, const Bi('', 'City Gate'), const LatLng(30.0096, 31.5724)),
                MapPin(7, const Bi('', 'La Vista City'), const LatLng(30.012, 31.585)),
              ],
              loadCompound: (id) async {
                asked.add(id);
                return CompoundPageData.fromJson(_json(7, 'La Vista City'));
              },
              openLink: (n, t) => opened.add((n, t)),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('plan-overlay')), findsOneWidget);
    expect(find.byKey(const Key('outline')), findsOneWidget);
    expect(find.byKey(const Key('pin-selected')), findsOneWidget);
    expect(find.byKey(const Key('pin-7')), findsOneWidget);
    expect(find.byKey(const Key('pin-644')), findsNothing); // the selected one is not drawn twice
    expect(tester.widget<Text>(find.byKey(const Key('map-name'))).data, 'City Gate');
    expect(find.text('New Cairo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-whatsapp')));
    expect(opened.single.$1, '+201001112233');
    expect(opened.single.$2, contains('City Gate'));
    await tester.tap(find.byKey(const Key('map-call')));
    expect(opened.last.$1, 'tel:+201001112233');

    await tester.tap(find.byKey(const Key('map-layers')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('pin-7')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(asked, [7]);
    expect(tester.widget<Text>(find.byKey(const Key('map-name'))).data, 'La Vista City');
    expect(find.byKey(const Key('plan-overlay')), findsNothing); // La Vista has no plan
    expect(find.byKey(const Key('outline')), findsOneWidget);
  });
}
