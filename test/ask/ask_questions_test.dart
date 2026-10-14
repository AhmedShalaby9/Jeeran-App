import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_api.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _refs = AskRefs.fromJson({
  'questions': [
    {'question': 'What is your budget?', 'options': ['Up to 5M', '5–10M', '10–20M']},
    {'question': 'Where?', 'options': ['Cairo', 'North Coast']},
    {'question': 'broken', 'options': ['only one']}, // dropped: a question needs at least two answers
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_askq_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  test('questions are parsed; one without two answers is dropped', () {
    expect(_refs.questions, hasLength(2));
    expect(_refs.questions.first.options, ['Up to 5M', '5–10M', '10–20M']);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final ar = locale.languageCode == 'ar';

    testWidgets('tap answers, then Send or "Show me anything" — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final sent = <String>[];
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
                  builder: (_, page, _) => KeyedSubtree(key: ObjectKey(page), child: SingleChildScrollView(child: page)),
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
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Send waits for an answer; answers are one per question and can be cleared
      host.value = AskQuestionsCard(questions: _refs.questions, enabled: true, onSend: sent.add);
      await settle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('q-send')));
      await settle();
      expect(sent, isEmpty);
      await tester.tap(find.byKey(const Key('q0-5–10M')));
      await tester.tap(find.byKey(const Key('q0-10–20M'))); // changes the first answer, not adds a second
      await tester.tap(find.byKey(const Key('q1-Cairo')));
      await tester.tap(find.byKey(const Key('q1-Cairo'))); // tapping again clears it
      await settle();
      await tester.tap(find.byKey(const Key('q-send')));
      await settle();
      expect(sent, ['What is your budget? 10–20M']);
      // after sending, the buttons are spent
      expect(find.byKey(const Key('q-send')), findsNothing);

      // "Show me anything" skips the questions
      sent.clear();
      host.value = AskQuestionsCard(questions: _refs.questions, enabled: true, onSend: sent.add);
      await settle();
      await tester.tap(find.byKey(const Key('q-anything')));
      await settle();
      expect(sent, ['concierge.q_anything_text'.tr()]);

      // an older answer (not the latest) does not take taps
      sent.clear();
      host.value = AskQuestionsCard(questions: _refs.questions, enabled: false, onSend: sent.add);
      await settle();
      await tester.tap(find.byKey(const Key('q0-Up to 5M')));
      await settle();
      expect(find.byKey(const Key('q-send')), findsNothing);
      expect(sent, isEmpty);
      expect(find.text(ar ? 'إرسال' : 'Send'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
