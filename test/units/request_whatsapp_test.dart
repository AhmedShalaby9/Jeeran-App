import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/units/presentation/request_call_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_req_wa').path);
    await Hive.openBox('jeeran_prefs');
  });

  testWidgets('a primary unit also offers WhatsApp, with the unit named in the message', (tester) async {
    final opened = <(String, String)>[];
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
            home: Scaffold(body: ValueListenableBuilder<Widget>(valueListenable: host, builder: (_, w, _) => KeyedSubtree(key: ObjectKey(w), child: w))),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 300));

    // no number to message: no button, the call request stays
    host.value = const RequestCallBar(propertyId: 1, price: 5000000);
    await tester.pump();
    expect(find.byKey(const Key('request-whatsapp')), findsNothing);
    expect(find.byKey(const Key('request-call')), findsOneWidget);

    host.value = RequestCallBar(
      propertyId: 1,
      price: 5000000,
      whatsapp: '+201000000000',
      whatsappText: 'Hello, I\'m interested in Villa (MAR-1)',
      openWhatsapp: (n, t) async => opened.add((n, t)),
    );
    await tester.pump();
    expect(find.byKey(const Key('request-whatsapp')), findsOneWidget);
    expect(find.byKey(const Key('request-call')), findsOneWidget);
    await tester.tap(find.byKey(const Key('request-whatsapp')));
    await tester.pump();
    expect(opened, [('+201000000000', "Hello, I'm interested in Villa (MAR-1)")]);
    expect(tester.takeException(), isNull);
  });
}
