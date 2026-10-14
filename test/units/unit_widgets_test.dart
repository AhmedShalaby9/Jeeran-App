import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/properties/domain/entities/property.dart';
import 'package:jeeran_flutter/features/units/data/payment_plan.dart';
import 'package:jeeran_flutter/features/units/data/unit_format.dart';
import 'package:jeeran_flutter/features/units/presentation/request_call_bar.dart';
import 'package:jeeran_flutter/features/units/presentation/unit_card.dart';
import 'package:jeeran_flutter/features/units/presentation/unit_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _plan({
  int years = 8,
  double dp = 5,
  double inst = 347344,
  double price = 11700000,
  Map<String, dynamic>? extra,
}) => {
  'frequency': 'quarterly',
  'years': years,
  'unit_price': price,
  'down_payment': price * dp / 100,
  'down_payment_percent': dp,
  'installment_amount': inst,
  'total_installments_amount': inst * years * 4,
  'is_cash': false,
  'bulk_payments': <dynamic>[],
  'milestones': [
    {'name': 'maintenance', 'total': 730200, 'included_in_price': false},
  ],
  ...?extra,
};

final _plans = PaymentPlan.listFrom([
  _plan(),
  _plan(years: 10, dp: 10, inst: 280000),
  _plan(
    years: 6,
    dp: 1.5,
    inst: 410000,
    extra: {
      'is_back_loaded': true,
      'bulk_payments': [
        {'value': 1170000, 'at_years': 2, 'at_months': 0},
      ],
    },
  ),
  _plan(
    years: 4,
    dp: 20,
    inst: 500000,
    extra: {'is_offer': true, 'discount_percent': 35},
  ),
  {
    'is_cash': true,
    'unit_price': 11700000,
    'frequency': 'one-time',
    'is_offer': true,
    'discount_percent': 0,
  },
]);

Property _unit({
  int beds = 2,
  bool launch = true,
  bool offer = true,
  bool noPhoto = false,
}) => Property(
  id: 7,
  titleEn: 'Apartment in Redwood Tower – 2 bedrooms',
  titleAr: 'شقة في ريدوود تاور – غرفتين نوم',
  propertyType: 'apartment',
  price: '15900000.00',
  size: '117.00',
  sizeMin: 117,
  sizeMax: 120,
  bedrooms: beds,
  bathrooms: 2,
  images: noPhoto ? const [] : const ['https://example.invalid/a.webp'],
  finishing: 'fully_finished',
  deliveryDate: '2029-02-28',
  isLaunch: launch,
  hasOffer: offer,
  offerDiscountPercent: 35,
  downPaymentPercent: 5,
  installmentYears: 8,
  paymentPlans: _plans,
  buildingEn: 'Redwood Tower',
);

/// One app per locale (translations load once); the screen under test is swapped in through [host].
Future<ValueNotifier<Widget>> _start(
  WidgetTester tester,
  Locale locale, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width * 3, 1800 * 3);
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
              builder: (_, page, _) => KeyedSubtree(
                key: ObjectKey(page),
                child: SingleChildScrollView(child: page),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return host;
}

Future<void> _settle(WidgetTester tester, [int ms = 300]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_units_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  test('prices are shortened for lists and spelled out on the page', () {
    expect(fmtShort(15900000), '15.9M');
    expect(fmtShort(1630000000), '1.63B');
    expect(fmtShort(347344), '347K');
    expect(fmtShort(2000000), '2M');
    expect(fmtFull(11700000), '11,700,000');
    expect(rangeShort(11700000, 16000000), '11.7M – 16M');
    expect(rangeShort(5000000, 5000000), '5M');
    expect(rangeNum(117, 120), '117–120');
    expect(rangeNum(84, 84), '84');
  });

  test(
    'the default plan is the one that matches the unit; cash is never the default',
    () {
      expect(defaultPlan(_plans, downPercent: 10, years: 10)!.years, 10);
      expect(defaultPlan(_plans)!.years, 8);
      expect(_plans.last.payInFull, isTrue);
      expect(_plans[3].discount, 35);
      expect(_plans.last.discount, isNull); // "0%" is an offer without a number
      expect(_plans.last.hasOffer, isTrue);
      expect(_plans[2].bulk.single.atYears, 2);
      expect(_plans.first.maintenance, 730200);
    },
  );

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final ar = locale.languageCode == 'ar';

    testWidgets('the unit card, in ${locale.languageCode}', (tester) async {
      final host = await _start(tester, locale, width: ar ? 390 : 700);

      // a full unit: short price, the plan, both marks, the building
      host.value = UnitCard(property: _unit());
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(
        (tester.widget(find.byKey(const Key('unit-price-7'))) as Text).data,
        contains('15.9M'),
      );
      expect(
        (tester.widget(find.byKey(const Key('unit-plan-7'))) as Text).data,
        contains('347K'),
      );
      expect(find.text(ar ? 'إطلاق' : 'Launch'), findsOneWidget);
      expect(find.text(ar ? 'عرض − 35٪' : 'Offer − 35%'), findsOneWidget);
      expect(find.textContaining('Redwood Tower'), findsWidgets);

      // a studio says what it is instead of "0 bd"; no photo; no marks
      host.value = UnitCard(
        property: _unit(beds: 0, launch: false, offer: false, noPhoto: true),
      );
      await _settle(tester);
      expect(find.textContaining('0 bd'), findsNothing);
      expect(find.text(ar ? 'شقة' : 'Apartment'), findsOneWidget);
      expect(find.text(ar ? 'إطلاق' : 'Launch'), findsNothing);
      expect(tester.takeException(), isNull);

      // the rest is language-neutral logic: checked once, in English
      if (!ar) {
        // the chips switch the one summary card
        host.value = PlansBlock(
          plans: _plans,
          headline: 15900000,
          deliveryYear: 2029,
          downPercent: 5,
          years: 8,
        );
        await _settle(tester);
        expect(find.text('Payment plans'), findsOneWidget);
        expect(find.byKey(const Key('plan-chip-0')), findsOneWidget);
        expect(
          find.textContaining('EGP 347,344', findRichText: true),
          findsOneWidget,
        ); // opens on 8 years · 5% down
        expect(find.text('Maintenance · one-time'), findsOneWidget);
        expect(find.text('Not included in the price'), findsOneWidget);
        expect(
          find.text("Plans are priced from the unit's lowest price"),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.byKey(const Key('plan-chip-2')),
          120,
          scrollable: find.descendant(
            of: find.byType(PlanChips),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(
          find.byKey(const Key('plan-chip-2')),
        ); // 6 yrs · 1.5% down, back-loaded, with a lump sum
        await _settle(tester);
        expect(
          find.textContaining('EGP 410,000', findRichText: true),
          findsOneWidget,
        );
        expect(find.textContaining('Lump sum'), findsWidgets);
        expect(find.textContaining('Back-loaded'), findsOneWidget);

        await tester.tap(find.byKey(const Key('plan-chip-4')));
        await _settle(tester);
        expect(find.text('PAY IN FULL'), findsOneWidget);
        expect(find.textContaining('Down payment'), findsNothing);
        expect(tester.takeException(), isNull);

        // floor plans open full screen and close again
        host.value = const FloorPlansBlock(
          urls: [
            'https://example.invalid/1.webp',
            'https://example.invalid/2.webp',
          ],
        );
        await _settle(tester);
        expect(find.text('Floor plans'), findsOneWidget);
        expect(find.text('2 plans'), findsOneWidget);
        await tester.tap(find.byKey(const Key('floor-plan-1')));
        await _settle(tester, 400);
        await _settle(tester, 400);
        expect(find.text('2 / 2'), findsOneWidget);
        await tester.tap(find.byKey(const Key('floor-plan-close')));
        await _settle(tester, 400);
        await _settle(tester, 400);
        expect(find.text('2 / 2'), findsNothing);

        // "Request a call" sends the unit to the team, once
        final sent = <(String, String)>[];
        host.value = RequestCallBar(
          propertyId: 7,
          title: 'Apartment in Redwood Tower',
          referenceCode: 'RED-00912',
          price: 15900000,
          fromPer: 'From 347K / quarter',
          send: (s, m) async => sent.add((s, m)),
        );
        await _settle(tester);
        expect(find.text('EGP 15.9M'), findsOneWidget);
        expect(find.text('From 347K / quarter'), findsOneWidget);
        await tester.tap(find.byKey(const Key('request-call')));
        await _settle(tester);
        await _settle(tester);
        expect(sent.length, 1);
        expect(sent.single.$1, contains('RED-00912'));
        expect(sent.single.$2, contains('#7'));
        expect(find.text('Requested'), findsOneWidget);
        await tester.tap(find.byKey(const Key('request-call')));
        await _settle(tester);
        expect(sent.length, 1); // a second tap does nothing
      }
    });
  }
}
