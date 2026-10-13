import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/search/data/search_api.dart';
import 'package:jeeran_flutter/features/search/presentation/all_developers_page.dart';
import 'package:jeeran_flutter/features/search/presentation/widgets/search_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 45 developers, the last ones with nothing live yet.
class _Fake extends ApiClient {
  final calls = <Map<String, dynamic>>[];
  static final all = [
    for (var i = 1; i <= 45; i++)
      {
        'id': i,
        'name_ar': 'مطور $i',
        'name_en': 'Developer ${i.toString().padLeft(2, '0')}',
        'logo': i == 1 ? 'https://x/logo.png' : null,
        'cover_image': i == 1 ? 'https://x/cover.jpg' : null,
        'is_verified': false,
        'compounds_count': i <= 30 ? 2 : 0,
        'units_count': i <= 30 ? 10 : 0,
      },
  ];

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    final q = queryParams ?? {};
    calls.add(q);
    final term = '${q['q'] ?? ''}'.toLowerCase();
    final rows = all
        .where(
          (d) => term.isEmpty || '${d['name_en']}'.toLowerCase().contains(term),
        )
        .toList();
    final limit = q['limit'] as int? ?? rows.length;
    final page = q['page'] as int? ?? 1;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'success': true,
        'data': rows.skip((page - 1) * limit).take(limit).toList(),
        'total': rows.length,
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_devs_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'all developers: paged, searchable, and says when nothing is live — ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 800 * 3);
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
                home: AllDevelopersPage(api: SearchApi(api), onOpen: (_) {}),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // first page only, with the full count in the header
        expect(tester.takeException(), isNull);
        expect(api.calls.first, {'page': 1, 'limit': 20});
        expect(find.text('45'), findsOneWidget);
        expect(
          find.byType(DevListRow, skipOffstage: false).evaluate().length,
          lessThan(25),
        );

        // scrolling loads the next pages until every developer is there
        for (var i = 0; i < 6; i++) {
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -3000),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(api.calls.map((c) => c['page']).toSet(), containsAll([1, 2, 3]));
        expect(
          api.calls.where((c) => c['page'] == 4),
          isEmpty,
        ); // nothing past the last page is asked for

        // the last developers have nothing live yet and say so
        expect(find.text('find.dev_nothing_live'.tr()), findsWidgets);

        // searching asks the server, starting again from page 1
        await tester.drag(
          find.byType(ListView).first,
          const Offset(0, 6000),
        ); // back to the top
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byKey(const Key('dev-q')), 'Developer 07');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(api.calls.last, {'page': 1, 'limit': 20, 'q': 'Developer 07'});
        expect(find.byType(DevListRow), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
