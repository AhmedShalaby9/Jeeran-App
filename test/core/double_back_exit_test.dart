import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/widgets/double_back_exit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_back_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('back goes home first, then needs a second press to exit — ${locale.languageCode}', (tester) async {
      var home = true;
      var exits = 0;
      var wentHome = 0;
      var now = DateTime(2026, 10, 14, 12);
      late StateSetter set;
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
              home: StatefulBuilder(
                builder: (context, setState) {
                  set = setState;
                  return DoubleBackExit(
                    atHome: home,
                    goHome: () => set(() {
                      home = true;
                      wentHome += 1;
                    }),
                    onExit: () => exits += 1,
                    clock: () => now,
                    child: const Scaffold(body: Text('main')),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));

      // on another tab: back returns to the first tab, nothing closes, no message
      set(() => home = false);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(wentHome, 1);
      expect(exits, 0);
      expect(find.byKey(const Key('back-again')), findsNothing);

      // first tab, first press: asks, does not exit
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(exits, 0);
      expect(find.byKey(const Key('back-again')), findsOneWidget);
      expect(find.text('explore.back_again'.tr()), findsOneWidget);

      // second press inside the window leaves
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exits, 1);

      // a press after the window asks again instead of leaving
      now = now.add(const Duration(seconds: 3));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exits, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });
  }
}
