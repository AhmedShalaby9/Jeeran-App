import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/admin/presentation/pages/admin_news_list_page.dart';
import 'package:jeeran_flutter/features/news/data/models/news_model.dart';
import 'package:jeeran_flutter/features/news/domain/entities/news.dart';
import 'package:shared_preferences/shared_preferences.dart';

News _n(int id, String title, bool active) =>
    NewsModel(id: id, title: title, content: '', media: const [], isActive: active, publishedAt: '', publishedBy: '');

void main() {
  _bothLanguages();
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_admin_news').path);
    await Hive.openBox('jeeran_prefs');
  });

  testWidgets('admin news: disabled articles stay listed, can be switched back on, and deleted', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final calls = <String>[];
    final host = ValueNotifier<Widget>(const SizedBox());
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
            home: ValueListenableBuilder<Widget>(valueListenable: host, builder: (_, w, _) => KeyedSubtree(key: ObjectKey(w), child: w)),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 300));

    host.value = AdminNewsListPage(
      load: () async => [_n(1, 'Live article', true), _n(2, 'Hidden article', false)],
      setActive: (id, v) async => calls.add('active:$id:$v'),
      remove: (id) async => calls.add('delete:$id'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // both are there, the disabled one included
    expect(find.text('Live article'), findsOneWidget);
    expect(find.text('Hidden article'), findsOneWidget);
    expect(find.byKey(const Key('news-add')), findsOneWidget);
    expect(tester.widget<Switch>(find.byKey(const Key('news-switch-2'))).value, isFalse);

    // switch the hidden one on, the live one off
    await tester.tap(find.byKey(const Key('news-switch-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('news-switch-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, ['active:2:true', 'active:1:false']);
    expect(tester.widget<Switch>(find.byKey(const Key('news-switch-2'))).value, isTrue);
    expect(tester.widget<Switch>(find.byKey(const Key('news-switch-1'))).value, isFalse);

    // delete asks first
    await tester.tap(find.byKey(const Key('news-delete-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls.where((c) => c.startsWith('delete')), isEmpty);
    await tester.tap(find.byKey(const Key('news-confirm-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls.last, 'delete:1');
    expect(find.text('Live article'), findsNothing);
    expect(find.text('Hidden article'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _bothLanguages() {
  test('NewsModel keeps both languages so the editor does not overwrite one with the other', () {
    final n = NewsModel.fromJson({
      'id': 6,
      'title': 'Egypt allocates',
      'title_ar': 'مصر تخصص',
      'title_en': 'Egypt allocates',
      'content': 'en body',
      'content_ar': 'نص',
      'content_en': 'en body',
      'media': ['a.jpg'],
      'is_active': true,
      'published_at': '2026-10-14T15:59:00.000Z',
      'published_by': null,
    });
    expect(n.titleAr, 'مصر تخصص');
    expect(n.titleEn, 'Egypt allocates');
    expect(n.contentAr, 'نص');
    expect(n.contentEn, 'en body');
    expect(n.publishedBy, '');
  });
}
