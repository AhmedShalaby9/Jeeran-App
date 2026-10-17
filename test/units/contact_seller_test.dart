import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/properties/presentation/widgets/property_v2_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_contact_seller').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('a resale unit offers call and WhatsApp — ${locale.languageCode}', (tester) async {
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

      var calls = 0, chats = 0;
      host.value = ContactSellerBar(sellerName: 'Mona', onCall: () => calls++, onWhatsapp: () => chats++);
      await settle();
      expect(find.text('prop.contact_seller'.tr()), findsOneWidget);
      await tester.tap(find.byKey(const Key('contact-seller')));
      await settle();
      expect(find.byKey(const Key('contact-call')), findsOneWidget);
      expect(find.byKey(const Key('contact-whatsapp')), findsOneWidget);
      expect(find.text('Mona'), findsOneWidget);
      await tester.tap(find.byKey(const Key('contact-whatsapp')));
      await settle();
      expect([calls, chats], [0, 1]);
      expect(find.byKey(const Key('contact-call')), findsNothing); // the sheet closed

      await tester.tap(find.byKey(const Key('contact-seller')));
      await settle();
      await tester.tap(find.byKey(const Key('contact-call')));
      await settle();
      expect([calls, chats], [1, 1]);

      // only a phone number: only the call option
      host.value = ContactSellerBar(onCall: () => calls++);
      await settle();
      await tester.tap(find.byKey(const Key('contact-seller')));
      await settle();
      expect(find.byKey(const Key('contact-call')), findsOneWidget);
      expect(find.byKey(const Key('contact-whatsapp')), findsNothing);
      await tester.tapAt(const Offset(20, 40)); // dismiss
      await settle();

      // no numbers at all: no bar
      host.value = const ContactSellerBar();
      await settle();
      expect(find.byKey(const Key('contact-seller')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
