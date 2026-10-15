import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/explore/presentation/widgets/explore_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_askentry_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final ar = locale.languageCode == 'ar';

    testWidgets('the Ask card replaces the search field and the mic — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      var asked = 0, talked = 0, searched = 0;
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
              home: Scaffold(
                body: ValueListenableBuilder<Widget>(valueListenable: host, builder: (_, w, _) => KeyedSubtree(key: ObjectKey(w), child: Center(child: w))),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));
      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      host.value = ExploreSearchEntry(onSearch: () => searched++, onAsk: () => asked++, onVoice: () => talked++);
      await settle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('ask-entry')), findsOneWidget);
      expect(find.text(ar ? 'كمبوند أو منطقة أو مطور' : 'Compound, area or developer'), findsNothing); // no search field
      expect(find.text(ar ? 'اسأل جيران' : 'ASK JEERAN'), findsOneWidget);
      // the first example question shows, then the next one takes over
      expect(find.byKey(const Key('ask-prompt-0')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 3300));
      expect(find.byKey(const Key('ask-prompt-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('ask-entry-text')));
      await tester.tap(find.byKey(const Key('explore-mic')));
      expect([asked, talked, searched], [1, 1, 0]);

      // no mic when voice is off; the review build (no Ask) keeps the plain search field
      host.value = ExploreSearchEntry(onSearch: () {}, onAsk: () {});
      await settle();
      expect(find.byKey(const Key('ask-entry')), findsOneWidget);
      expect(find.byKey(const Key('explore-mic')), findsNothing);
      host.value = ExploreSearchEntry(onSearch: () => searched++);
      await settle();
      expect(find.byKey(const Key('ask-entry')), findsNothing);
      expect(find.text(ar ? 'كمبوند أو منطقة أو مطور' : 'Compound, area or developer'), findsOneWidget);
      await tester.tap(find.text(ar ? 'كمبوند أو منطقة أو مطور' : 'Compound, area or developer'));
      expect(searched, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
