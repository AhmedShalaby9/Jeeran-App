import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_api.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_no_match.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

// What the chat sends back when "a 3-bedroom townhouse in Roudy under 3M" finds nothing.
final _refs = AskRefs.fromJson({
  'no_match': {
    'filters': {'property_type': 'townhouse', 'property_status': 'for_sale', 'compound_id': 861, 'bedrooms': 3, 'max_price': 3000000},
    'names': {'compound_en': 'Roudy', 'compound_ar': 'رودي'},
    'text': 'townhouse 3 bed under 3M',
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_ask_no_match').path);
    await Hive.openBox('jeeran_prefs');
  });

  test('the unanswered search is read from the reference', () {
    expect(_refs.noMatch, isNotNull);
    expect(_refs.noMatch!.filters['bedrooms'], 3);
    expect(_refs.noMatch!.names['compound_en'], 'Roudy');
    expect(_refs.noMatch!.text, 'townhouse 3 bed under 3M');
    expect(AskRefs.fromJson({'properties': <dynamic>[]}).noMatch, isNull);
    expect(AskRefs.fromJson({'no_match': {'filters': <String, dynamic>{}}}).noMatch, isNull);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('no match: card, Notify me saves the search, Not now hides it — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final saved = <Map<String, dynamic>>[];
      var failNext = true;
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
                  builder: (_, w, _) => KeyedSubtree(key: ObjectKey(w), child: w),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));

      host.value = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AskAssistantMsg(
            text: 'Nothing matches.',
            tail: '',
            refs: _refs,
            typing: false,
            onProperty: (_) {},
            onCompound: (_, _) {},
            onNews: () {},
          ),
        ],
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // the card shows what was asked for
      expect(find.byKey(const Key('ask-no-match')), findsOneWidget);
      expect(find.text('concierge.nm_title'.tr()), findsOneWidget);
      expect(find.text(locale.languageCode == 'ar' ? 'رودي' : 'Roudy'), findsOneWidget);
      expect(find.text('type.townhouse'.tr()), findsOneWidget);
      expect(find.text('concierge.nm_beds'.tr(namedArgs: {'n': '3'})), findsOneWidget);
      expect(find.text('concierge.nm_up_to'.tr(namedArgs: {'v': '3M'})), findsOneWidget);

      // a card with an injected saver: the first try fails and says so, the second saves
      host.value = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AskNoMatchCard(
            data: _refs.noMatch!,
            save: (d, lang) async {
              if (failNext) {
                failNext = false;
                throw Exception('offline');
              }
              saved.add({'filters': d.filters, 'text': d.text, 'lang': lang});
            },
          ),
        ],
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('ask-no-match-notify')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('concierge.nm_failed'.tr()), findsOneWidget);
      expect(saved, isEmpty);

      await tester.tap(find.byKey(const Key('ask-no-match-notify')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(saved, hasLength(1));
      expect(saved.single['lang'], locale.languageCode);
      expect(saved.single['text'], 'townhouse 3 bed under 3M');
      expect((saved.single['filters'] as Map)['bedrooms'], 3);
      expect(find.text('concierge.nm_saved_title'.tr()), findsOneWidget);
      expect(find.byKey(const Key('ask-no-match-notify')), findsNothing);

      // Not now removes the card
      host.value = ListView(children: [AskNoMatchCard(data: _refs.noMatch!, save: (_, _) async {})]);
      await tester.pump();
      await tester.tap(find.byKey(const Key('ask-no-match-skip')));
      await tester.pump();
      expect(find.byKey(const Key('ask-no-match')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
