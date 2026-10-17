import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/units/presentation/phone_confirm_sheet.dart';
import 'package:jeeran_flutter/features/units/presentation/request_call_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_phone_confirm').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('an unverified number is confirmed or changed before the request — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
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
              home: Scaffold(
                body: ValueListenableBuilder<Widget>(
                  valueListenable: host,
                  builder: (_, w, _) => KeyedSubtree(key: ObjectKey(w), child: Align(alignment: Alignment.bottomCenter, child: w)),
                ),
              ),
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

      // the "request sent" snackbar sits over the button for a few seconds
      Future<void> afterSnack() => tester.pump(const Duration(seconds: 6));

      final sent = <int>[];
      final saved = <String>[];
      var failSave = false;
      Widget bar(CallerPhone p) => RequestCallBar(
        propertyId: 7,
        price: 15900000,
        loadPhone: () async => p,
        savePhone: (n) async {
          if (failSave) throw Exception('bad number');
          saved.add(n);
        },
        send: (id) async => sent.add(id),
      );

      // verified: straight through, no sheet
      host.value = bar(const CallerPhone('+201011112222', true));
      await settle();
      await tester.tap(find.byKey(const Key('request-call')));
      await settle();
      expect(find.byKey(const Key('phone-continue')), findsNothing);
      expect(sent, [7]);
      await afterSnack();

      // unverified, dismissed: nothing is sent and the button is usable again
      sent.clear();
      host.value = bar(const CallerPhone('+201011112222', false));
      await settle();
      await tester.tap(find.byKey(const Key('request-call')));
      await settle();
      expect(find.text('+201011112222'), findsOneWidget);
      expect(find.text('unit.phone_not_verified'.tr()), findsOneWidget);
      await tester.tapAt(const Offset(20, 40));
      await settle();
      expect(sent, isEmpty);
      expect(find.byKey(const Key('request-call')), findsOneWidget);

      // unverified, continue as it is: sent, number untouched
      await tester.tap(find.byKey(const Key('request-call')));
      await settle();
      await tester.tap(find.byKey(const Key('phone-continue')));
      await settle();
      await settle();
      expect(sent, [7]);
      expect(saved, isEmpty);
      await afterSnack();

      // unverified, change it: bad number stays on the sheet; a good one is saved, then sent
      sent.clear();
      host.value = bar(const CallerPhone('+201011112222', false));
      await settle();
      await tester.tap(find.byKey(const Key('request-call')));
      await settle();
      await tester.tap(find.byKey(const Key('phone-change')));
      await settle();
      expect(find.byKey(const Key('phone-input')), findsOneWidget);
      await tester.tap(find.byKey(const Key('phone-save')));
      await settle();
      expect(find.byKey(const Key('phone-error')), findsOneWidget); // empty
      failSave = true;
      await tester.enterText(find.byType(TextField), '12345678');
      await tester.tap(find.byKey(const Key('phone-save')));
      await settle();
      expect(find.byKey(const Key('phone-error')), findsOneWidget); // the server said no
      expect(sent, isEmpty);
      failSave = false;
      await tester.enterText(find.byType(TextField), '01099998888');
      await tester.tap(find.byKey(const Key('phone-save')));
      await settle();
      await settle();
      expect(saved, ['01099998888']);
      expect(sent, [7]);
      await afterSnack();

      // no number at all: asks for one straight away, with nothing to continue with
      sent.clear();
      saved.clear();
      host.value = bar(const CallerPhone(null, false));
      await settle();
      await tester.tap(find.byKey(const Key('request-call')));
      await settle();
      expect(find.byKey(const Key('phone-continue')), findsNothing);
      expect(find.byKey(const Key('phone-input')), findsOneWidget);
      await tester.enterText(find.byType(TextField), '+20 10 1111 2222');
      await tester.tap(find.byKey(const Key('phone-save')));
      await settle();
      await settle();
      expect(saved, ['+20 10 1111 2222']);
      expect(sent, [7]);
      expect(tester.takeException(), isNull);
    });
  }
}
