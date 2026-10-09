import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/news/v2/news_api.dart';
import 'package:jeeran_flutter/features/news/v2/news_article_page.dart';
import 'package:jeeran_flutter/features/news/v2/news_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _row(int id, {String? content}) => {
  'id': id,
  'title': 'Story $id',
  if (content != null) 'content': content else 'excerpt': 'Excerpt $id',
  'media': id == 1 ? ['https://x/a.jpg', 'https://x/v.mp4'] : <String>[],
  'published_at': DateTime.now()
      .subtract(Duration(days: id))
      .toUtc()
      .toIso8601String(),
};

class _FakeApi extends ApiClient {
  final int total;
  _FakeApi(this.total);

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    dynamic data;
    if (path == '/news') {
      final page = queryParams!['page'] as int;
      final all = [for (var i = 1; i <= total; i++) _row(i)];
      data = all
          .skip((page - 1) * NewsApi.pageSize)
          .take(NewsApi.pageSize)
          .toList();
    } else {
      final id = int.parse(path.split('/').last);
      data = _row(id, content: 'First para.\n\nSecond para.');
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'success': true, 'data': data},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'item parsing: video is not a cover, paragraphs split on blank lines',
    () {
      final n = NewsItem.fromJson(_row(1, content: 'A\n\nB\n \nC'));
      expect(n.hasVideo, isTrue);
      expect(n.cover, 'https://x/a.jpg');
      expect(n.paragraphs, ['A', 'B', 'C']);
      expect(NewsItem.fromJson(_row(2)).cover, isNull);
    },
  );

  group('screens', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_news_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets('list and article in ${locale.languageCode}', (tester) async {
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
                home: ValueListenableBuilder<Widget>(
                  valueListenable: host,
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

        // empty
        host.value = NewsListPage(api: NewsApi(_FakeApi(0)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('news.empty_title'.tr()), findsOneWidget);

        // a short list: lead + earlier + the end note
        host.value = NewsListPage(api: NewsApi(_FakeApi(4)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('Story 1'), findsOneWidget);
        expect(find.text('news.earlier'.tr().toUpperCase()), findsOneWidget);
        expect(find.text('Story 4'), findsOneWidget);
        expect(find.text('news.end'.tr()), findsOneWidget);

        // open the lead: full text in paragraphs, the other stories below
        await tester.tap(find.text('Story 1'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(find.text('First para.'), findsOneWidget);
        expect(find.text('Second para.'), findsOneWidget);
        expect(find.text('news.more'.tr().toUpperCase()), findsOneWidget);

        // by id only (from a notification)
        host.value = NewsArticlePage(id: 3, api: NewsApi(_FakeApi(4)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Story 3'), findsOneWidget);
        expect(find.text('First para.'), findsOneWidget);
      });
    }
  });
}
