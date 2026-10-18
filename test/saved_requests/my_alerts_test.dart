import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/saved_requests/my_alerts_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_alerts_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('My alerts lists the searches and stops one — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final stopped = <int>[];
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
              home: ValueListenableBuilder<Widget>(valueListenable: host, builder: (_, w, _) => KeyedSubtree(key: ObjectKey(w), child: w)),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));

      host.value = MyAlertsPage(
        load: () async => [
          SavedAlert.fromJson({
            'id': 5,
            'original_text': 'townhouse 3 bed under 3M',
            'filters': {'property_type': 'townhouse', 'bedrooms': 3, 'max_price': 3000000},
            'names': {'compound_en': 'Roudy', 'compound_ar': 'رودي'},
            'created_at': '2026-10-18T10:00:00.000Z',
          }),
          SavedAlert.fromJson({'id': 6, 'original_text': '', 'filters': {'property_type': 'villa'}, 'created_at': '2026-10-17T10:00:00.000Z'}),
        ],
        cancel: (id) async => stopped.add(id),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('alert-5')), findsOneWidget);
      expect(find.text('townhouse 3 bed under 3M'), findsOneWidget);
      expect(find.text(locale.languageCode == 'ar' ? 'رودي' : 'Roudy'), findsOneWidget);
      expect(find.text('type.villa'.tr()), findsOneWidget);

      await tester.tap(find.byKey(const Key('alert-stop-5')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(stopped, [5]);
      expect(find.byKey(const Key('alert-5')), findsNothing);
      expect(find.byKey(const Key('alert-6')), findsOneWidget);

      await tester.tap(find.byKey(const Key('alert-stop-6')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('alerts-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
