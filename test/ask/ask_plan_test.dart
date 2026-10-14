import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_api.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_widgets.dart';
import 'package:jeeran_flutter/features/units/presentation/unit_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _refs = AskRefs.fromJson({
  'properties': [
    {'id': 7, 'title_en': 'Apartment in Redwood Tower', 'title_ar': 'شقة في ريدوود تاور', 'price': 15900000, 'images': <String>[]},
    {'id': 8, 'title_en': 'Studio in The Gryd', 'title_ar': 'استوديو في ذا جريد', 'price': 2360000, 'images': <String>[]},
  ],
  'plans': [
    {
      'plan_index': 0,
      'plans_count': 5,
      'property': {
        'id': 7,
        'title_en': 'Apartment in Redwood Tower',
        'title_ar': 'شقة في ريدوود تاور',
        'price': 15900000,
        'images': <String>[],
        'delivery_year': 2029,
        'published_on': '2026-10-14',
      },
      'plan': {
        'frequency': 'quarterly',
        'years': 8,
        'unit_price': 11700000,
        'down_payment': 585000,
        'down_payment_percent': 5,
        'installment_amount': 347344,
        'total_installments_amount': 11115000,
        'is_cash': false,
        'bulk_payments': <dynamic>[],
        'milestones': <dynamic>[],
      },
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_askplan_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  test('a plan the assistant quoted is parsed from the reference', () {
    expect(_refs.plans, hasLength(1));
    expect(_refs.plans.single.plan.installment, 347344);
    expect(_refs.plans.single.plansCount, 5);
    expect(_refs.plans.single.deliveryYear, 2029);
    expect(_refs.plans.single.propertyId, 7);
    expect(AskRefs.fromJson({'plans': [{'plan': {}}]}).plans, isEmpty); // incomplete: dropped
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final ar = locale.languageCode == 'ar';

    testWidgets('Ask shows the quoted plan as the property page does — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final opened = <Map<String, dynamic>>[];
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
                body: SingleChildScrollView(
                  child: AskAssistantMsg(
                    text: 'The lowest down payment is **1.5%**.',
                    tail: '',
                    refs: _refs,
                    typing: false,
                    onProperty: opened.add,
                    onCompound: (_, _) {},
                    onNews: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('ask-plan-7')), findsOneWidget);
      expect(find.byType(PlanSummary), findsOneWidget);
      expect(find.textContaining('EGP 347,344', findRichText: true), findsOneWidget);
      expect(find.text('unit.see_all_plans'.tr(namedArgs: {'n': '5'})), findsNothing); // part of a longer line
      expect(find.textContaining('unit.see_all_plans'.tr(namedArgs: {'n': '5'})), findsOneWidget);
      expect(find.text('unit.published_figures'.tr(namedArgs: {'date': DateFormat('d MMM y', ar ? 'ar' : 'en').format(DateTime(2026, 10, 14))})), findsOneWidget);
      // the unit the card is about is not shown again in the rail; the other one is
      expect(find.byType(AskPropertyRail), findsOneWidget);

      await tester.tap(find.byKey(const Key('ask-plan-open-7')));
      await tester.pump();
      expect(opened.single['id'], 7);
    });
  }
}
