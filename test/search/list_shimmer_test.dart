import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/explore/presentation/pages/all_compounds_page.dart';
import 'package:jeeran_flutter/features/search/data/search_api.dart';
import 'package:jeeran_flutter/features/search/presentation/launches_page.dart';
import 'package:jeeran_flutter/features/search/presentation/offers_page.dart';
import 'package:jeeran_flutter/features/search/presentation/search_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers only when the test says so, so the loading state can be looked at.
class _SlowApi extends ApiClient {
  final gate = Completer<void>();

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    await gate.future;
    Response ok(dynamic body) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: body,
    );
    if (path == '/properties') {
      return ok({
        'success': true,
        'data': [
          {
            'id': 1,
            'title_ar': 'وحدة',
            'title_en': 'Apartment unit',
            'property_type': 'apartment',
            'price': '9000000',
            'size': '100',
            'bedrooms': 2,
            'bathrooms': 1,
            'images': <String>[],
            'has_offer': true,
          },
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
      });
    }
    if (path == '/compounds') {
      return ok({
        'success': true,
        'data': [
          {
            'id': 5,
            'name_en': 'Marassi',
            'name_ar': 'مراسي',
            'developer': {'id': 1, 'name_en': 'Emaar', 'name_ar': 'إعمار'},
          },
        ],
        'pagination': {'total': 1},
      });
    }
    if (path.startsWith('/properties/'))
      return ok({'success': true, 'data': {}});
    return ok({'success': true, 'data': <dynamic>[]});
  }
}

final _home = ValueNotifier<Widget>(const SizedBox());

/// Translations load on a real async turn, so the app is built once; each screen is then swapped in with fake time.
Future<void> _boot(WidgetTester tester, Locale locale) async {
  _home.value = const SizedBox();
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
            valueListenable: _home,
            builder: (_, page, _) =>
                KeyedSubtree(key: ObjectKey(page), child: page),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _show(WidgetTester tester, Widget page) async {
  _home.value = page;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_shimmer_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'launches, offers and compounds show shimmer while loading — ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await _boot(tester, locale);

        // compounds
        var api = _SlowApi();
        await _show(tester, AllCompoundsPage(api: SearchApi(api)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('compound-shimmer')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        api.gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('compound-shimmer')), findsNothing);
        expect(find.byKey(const Key('compound-row-5')), findsOneWidget);

        // launches and offers (compounds)
        api = _SlowApi();
        await _show(tester, LaunchesPage(api: SearchApi(api), onOpen: (_) {}));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('launch-shimmer')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        api.gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('launch-shimmer')), findsNothing);

        // launches and offers (units)
        api = _SlowApi();
        await _show(tester, OffersPage(api: SearchApi(api)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('unit-shimmer')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        api.gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('unit-shimmer')), findsNothing);
        expect(find.byKey(const Key('unit-card-1')), findsOneWidget);

        // the Search screen: developers rail, launches rail and the unit rows
        api = _SlowApi();
        await _show(tester, SearchHome(api: SearchApi(api)));
        expect(find.byKey(const Key('dev-rail-shimmer')), findsOneWidget);
        expect(find.byKey(const Key('promo-rail-shimmer')), findsOneWidget);
        expect(find.byKey(const Key('results-shimmer')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        api.gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('dev-rail-shimmer')), findsNothing);
        expect(find.byKey(const Key('promo-rail-shimmer')), findsNothing);
        expect(find.byKey(const Key('results-shimmer')), findsNothing);
      },
    );
  }
}
