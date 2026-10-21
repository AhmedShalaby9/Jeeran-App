import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_flow_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Same pattern as the other widget tests: pump an empty host, let the translations load, then swap the page in.
Future<void> showPage(WidgetTester t, Widget page) async {
  final host = ValueNotifier<Widget>(const SizedBox());
  await t.pumpWidget(
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
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await t.pump(const Duration(milliseconds: 300));
  host.value = page;
  await t.pump();
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> setUpAdStudioTests() async {
  // the display font can't download in tests
  AdStyles.displayOverride = (c, size) => TextStyle(fontSize: size);
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  Hive.init(Directory.systemTemp.createTempSync('jeeran_ad_studio').path);
  await Hive.openBox('jeeran_prefs');
}

Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
  await t.pump(const Duration(milliseconds: 300));
}
