import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/search/data/search_api.dart';
import 'package:jeeran_flutter/features/search/data/search_filters.dart';
import 'package:jeeran_flutter/features/search/presentation/search_home.dart';
import 'package:jeeran_flutter/features/search/presentation/widgets/search_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _unit(int id, String title) => {
      'id': id,
      'title_ar': title,
      'title_en': title,
      'price': '12400000.00',
      'bedrooms': 3,
      'bathrooms': 2,
      'size': '184.00',
      'images': <String>[],
      'is_featured': id == 1,
      'effective': {'is_ready': true, 'delivery_date': '2024-01-01'},
      'project': {
        'id': 1,
        'name_ar': 'مراسي',
        'name_en': 'Marassi',
        'developer': {'id': 1, 'name_ar': 'إعمار', 'name_en': 'Emaar Misr'},
      },
    };

/// Answers every Search endpoint. Developer 2 has nothing until the budget is raised.
class _FakeApi extends ApiClient {
  final calls = <String>[];

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async {
    calls.add('$path ${queryParams ?? {}}');
    Response ok(dynamic body) => Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: body);
    final q = queryParams ?? {};
    switch (path) {
      case '/properties':
        final empty = q['developer_id'] == 2 && q['max_price'] == null;
        final items = empty ? <Map<String, dynamic>>[] : [_unit(1, 'Sea view chalet'), _unit(2, 'Lagoon chalet')];
        return ok({'success': true, 'data': items, 'pagination': {'page': 1, 'limit': 20, 'total': items.length, 'pages': 1}});
      case '/properties/count':
        return ok({'success': true, 'data': {'count': 184}});
      case '/properties/relax':
        return ok({
          'success': true,
          'data': {
            'count': 0,
            'suggestions': [
              {'kind': 'raise_max_price', 'max_price': 16000000, 'count': 42},
            ],
          },
        });
      case '/developers/summary':
        return ok({
          'success': true,
          'data': [
            {'id': 1, 'name_ar': 'إعمار', 'name_en': 'Emaar Misr', 'logo': null, 'is_verified': true, 'compounds_count': 4, 'units_count': 612},
            {'id': 2, 'name_ar': 'بالم هيلز', 'name_en': 'Palm Hills', 'logo': null, 'is_verified': false, 'compounds_count': 9, 'units_count': 1240},
          ],
        });
      case '/promotions':
        return ok({
          'success': true,
          'data': [
            {
              'id': 5, 'type': 'launch', 'title_ar': 'مارينا رايز', 'title_en': 'Marina Rise', 'sub_en': 'From 11.9M', 'image': null,
              'video_url': null, 'compound_id': 1, 'ends_at': null,
              'compound': {'id': 1, 'name_ar': 'مراسي', 'name_en': 'Marassi', 'developer': {'name_ar': 'إعمار', 'name_en': 'Emaar Misr'}},
            },
          ],
        });
      case '/areas':
        return ok({
          'success': true,
          'data': [
            {'id': 3, 'name_ar': 'الساحل الشمالي', 'name_en': 'North Coast', 'image': null, 'listing_count': 140},
          ],
        });
      default:
        return ok({'success': true, 'data': <dynamic>[]});
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('filters', () {
    test('query carries only what is set; sort is separate', () {
      expect(const SearchFilters().toQuery(), isEmpty);
      expect(const SearchFilters().isActive, isFalse);
      final f = const SearchFilters(
        types: {'chalet', 'villa'}, beds: '5+', minPrice: 6000000, maxPrice: 14000000, delivery: 'ready',
        amenities: {'sea_view', 'roof'}, areaId: 3, featured: true, verifiedOnly: true, sort: 'price_asc',
      );
      expect(f.toQuery(), {
        'type': 'chalet,villa', 'bedrooms': '5+', 'min_price': 6000000, 'max_price': 14000000, 'delivery': 'ready',
        'amenities': 'sea_view,roof', 'area_id': 3, 'is_featured': 'true', 'verified_only': 'true',
      });
      expect(f.sortQuery(), {'sort': 'price', 'order': 'ASC'});
      expect(f.activeCount, 2 + 1 + 1 + 1 + 2 + 1 + 1 + 1);
      expect(const SearchFilters(sort: 'price_desc').isActive, isFalse);
    });

    test('dropping a condition by the server\'s name', () {
      const f = SearchFilters(types: {'villa'}, minPrice: 1, maxPrice: 2, developerId: 4, developerName: 'X');
      expect(f.without('price_max').maxPrice, isNull);
      expect(f.without('price_max').minPrice, 1);
      expect(f.without('developer').developerName, isNull);
      expect(f.without('type').types, isEmpty);
    });

    test('survives being stored on the device', () {
      const f = SearchFilters(q: 'marassi', types: {'chalet'}, beds: '3', areaId: 2, areaName: 'North Coast', verifiedOnly: true);
      expect(SearchFilters.fromJson(f.toJson()), f);
      expect(SearchFilters.fromJson(<String, dynamic>{'sort': 'nonsense'}).sort, 'newest');
    });

    test('relax suggestions apply themselves', () {
      const f = SearchFilters(types: {'chalet'}, maxPrice: 10000000);
      expect(const RelaxSuggestion('raise_max_price', 42, price: 16000000).applyTo(f).maxPrice, 16000000);
      expect(const RelaxSuggestion('drop_filter', 9, filter: 'type').applyTo(f).types, isEmpty);
    });

    test('developer initials', () {
      const d = DeveloperSummary(1, 'طلعت', 'Talaat Moustafa Group', null, true, 1, 1);
      expect(d.short, 'TMG');
      expect(const DeveloperSummary(2, '', 'Palm', null, false, 1, 1).short, 'PA');
    });
  });

  group('screen', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_search_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      final lang = locale.languageCode;
      testWidgets('browse → results → filters → nothing matches → widen, in $lang', (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 2400 * 3); // tall, so the lazy list builds every row
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
                home: SearchHome(api: SearchApi(api)),
              ),
            ),
          ),
        );
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);

        // browse: rails and the list are there
        expect(find.text('find.devs_title'.tr()), findsOneWidget);
        expect(find.text(lang == 'ar' ? 'بالم هيلز' : 'Palm Hills'), findsOneWidget);
        expect(find.text(lang == 'ar' ? 'مارينا رايز' : 'Marina Rise'), findsOneWidget);
        expect(find.byType(UnitRow), findsNWidgets(2));
        expect(find.text('find.sort_newest'.tr()), findsOneWidget);

        // a developer opens results filtered to them; nothing is listed → the widen suggestion
        await tester.tap(find.text(lang == 'ar' ? 'بالم هيلز' : 'Palm Hills'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(api.calls.any((c) => c.startsWith('/properties {') && c.contains('developer_id: 2')), isTrue);
        expect(find.byType(RemovableChip), findsOneWidget);
        expect(find.text('find.empty_title'.tr()), findsOneWidget);
        final raise = 'find.raise_btn'.tr(args: ['16M']);
        expect(find.text(raise), findsOneWidget);

        // widening re-runs the search with the new cap and finds the units
        await tester.tap(find.text(raise));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(api.calls.last, contains('max_price: 16000000'));
        expect(find.byType(UnitRow), findsNWidgets(2));
        expect(find.byType(RemovableChip), findsNWidgets(2));

        // the filter sheet opens with a live count
        await tester.tap(find.text('find.filters'.tr()));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(find.text('find.matching_now'.tr()), findsOneWidget);
        expect(find.text('find.show_results'.tr()), findsOneWidget);
        expect(api.calls.any((c) => c.startsWith('/properties/count')), isTrue);
      });
    }
  });
}
