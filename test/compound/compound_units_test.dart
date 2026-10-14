import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/di/injection_container.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/core/services/app_settings_service.dart';
import 'package:jeeran_flutter/features/compounds/presentation/pages/compound_page.dart';
import 'package:jeeran_flutter/features/developers/presentation/pages/developer_page.dart';
import 'package:jeeran_flutter/features/follow/data/follow_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _compound({int primary = 3, int resale = 0}) => {
  'id': 5,
  'name_ar': 'ذا جريد',
  'name_en': 'The Gryd',
  'desc_ar': 'وصف',
  'desc_en': 'A mid-rise compound.',
  'main_image': null,
  'gallery': [],
  'developer': {'id': 1, 'name_ar': 'ريدوود', 'name_en': 'Redwood Developments', 'logo': null, 'is_verified': false, 'is_top': true, 'compounds_count': 4, 'units_count': 107},
  'area': {'id': 2, 'name_ar': 'القاهرة الجديدة', 'name_en': 'New Cairo'},
  'status': primary > 0 ? 'selling' : null,
  'min_price': primary > 0 ? 2360000 : null,
  'units_count': primary + resale,
  'primary_count': primary,
  'resale_count': resale,
  'is_following': false,
  'phases': [],
  'unit_types': primary > 0 ? ['apartment', 'duplex'] : [],
  'size_min': primary > 0 ? 56 : null,
  'size_max': primary > 0 ? 168 : null,
};

Map<String, dynamic> _unit(int id, String type, int beds, double price) => {
  'id': id,
  'title_ar': 'وحدة $id',
  'title_en': '$type unit $id',
  'property_type': type,
  'price': '$price',
  'size': '120.00',
  'bedrooms': beds,
  'bathrooms': 2,
  'images': <String>[],
  'is_launch': id == 3,
  'has_offer': id == 1,
  'offer_discount_percent': id == 1 ? '12.00' : null,
  'source': {'scraped_at': '2026-10-14'},
};

final _developer = {
  'id': 1,
  'name_ar': 'أركان بالم',
  'name_en': 'Arkan Palm Developments',
  'logo': null,
  'is_verified': false,
  'is_top': true,
  'is_following': false,
  'followers_count': 0,
  'stats': {'compounds_count': 1, 'units_count': 0},
  'compounds': [
    {'id': 5, 'name_ar': 'أركان بالم 205', 'name_en': 'Arkan Palm 205', 'main_image': null, 'is_active': true, 'area': {'name_ar': 'الشيخ زايد', 'name_en': 'Sheikh Zayed'}, 'units_count': 0},
  ],
};

class _Api extends ApiClient {
  final Map<String, dynamic> compound;
  final List<Map<String, dynamic>> units;
  _Api(this.compound, this.units);

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async {
    Response ok(dynamic data) => Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: data);
    if (path.startsWith('/compounds/')) return ok({'success': true, 'data': compound});
    if (path.startsWith('/developers/')) return ok({'success': true, 'data': _developer});
    if (path == '/properties') return ok({'success': true, 'data': units});
    return ok({'success': true, 'data': {'is_following': false}});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_cunits_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  Future<void> useApi(Map<String, dynamic> compound, List<Map<String, dynamic>> units) async {
    await sl.reset();
    final api = _Api(compound, units);
    sl.registerSingleton<ApiClient>(api);
    sl.registerSingleton<FollowService>(FollowService(apiClient: api));
    AppSettingsService.instance.settings = const AppSettings();
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final ar = locale.languageCode == 'ar';

    testWidgets('compound units grouped by type and the empty state — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
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
              home: ValueListenableBuilder<Widget>(valueListenable: host, builder: (_, page, _) => KeyedSubtree(key: ObjectKey(page), child: page)),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));
      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }

      // ── a compound with units: price line, type chips, tab counts, units grouped by type
      await useApi(_compound(), [_unit(1, 'apartment', 2, 4850000), _unit(2, 'apartment', 3, 6420000), _unit(3, 'duplex', 3, 8100000)]);
      host.value = const CompoundPage(compoundId: 5);
      await settle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('compound-from')), findsOneWidget);
      // Follow sits on the photo, top-right, in a white container beside the bell — not as a bar in the page
      expect(find.byKey(const Key('follow-button')), findsOneWidget);
      expect(find.byKey(const Key('alert-bell')), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(const Key('follow-button'))).dy, lessThan(120));
      // on the far side from the back button: right in English, left in Arabic
      final followX = tester.getTopLeft(find.byKey(const Key('follow-button'))).dx;
      expect(followX, ar ? lessThan(195) : greaterThan(195));
      expect(find.text('follow.follow_short'.tr()), findsOneWidget);
      // the Selling tag beside the name, and "area · by developer" as one line
      expect(find.byKey(const Key('selling-tag')), findsOneWidget);
      expect(find.byKey(const Key('developer-link')), findsOneWidget);
      expect(find.byKey(const Key('tab-count-0')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('tab-count-0')), matching: find.text('3')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('tab-count-1')), matching: find.text('0')), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const Key('unit-card-1')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('unit-card-1')), findsOneWidget);
      expect(find.text('unit.models_n'.tr(namedArgs: {'n': '2'})), findsOneWidget); // two apartment models
      expect(find.text(ar ? 'إطلاق' : 'Launch'), findsOneWidget);

      // no bedroom filter: every unit stays in its type group
      expect(find.byKey(const Key('beds-2')), findsNothing);
      expect(find.byKey(const Key('unit-card-2')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // ── a compound with no units stays visible, with a Follow button
      await useApi(_compound(primary: 0), []);
      host.value = const CompoundPage(compoundId: 5);
      await settle();
      expect(find.byKey(const Key('no-units-title')), findsOneWidget);
      expect(find.text('unit.no_units_title'.tr()), findsOneWidget);
      expect(find.byKey(const Key('follow-button')), findsWidgets);
      expect(find.byKey(const Key('compound-from')), findsNothing); // no price to quote
      expect(tester.takeException(), isNull);

      // ── a thin developer: Top mark (not the verified tick), initials, and its zero units said plainly
      host.value = const DeveloperPage(developerId: 1);
      await settle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('top-badge')), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
      expect(find.byKey(const Key('dev-no-units')), findsOneWidget);
      expect(find.textContaining('unit.no_units_yet'.tr()), findsOneWidget); // on its compound's row
      expect(find.text(ar ? 'أب' : 'AP'), findsOneWidget); // initials tile
    });
  }
}
