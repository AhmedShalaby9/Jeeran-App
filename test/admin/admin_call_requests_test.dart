import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/admin/presentation/pages/admin_call_requests_page.dart';
import 'package:jeeran_flutter/features/notifications/v2/notif_actions.dart';
import 'package:jeeran_flutter/features/notifications/v2/notif_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _row(int id, String status, {String? note, bool verified = true}) => {
  'id': id,
  'status': status,
  'property_id': 10 + id,
  'property_title': 'Villa $id',
  'reference_code': 'MAR-0000$id',
  'price': '5000000.00',
  'contact_phone': '+20100000000$id',
  'phone_verified': verified,
  'admin_note': note,
  'created_at': '2026-10-19T08:00:00.000Z',
  'user': {'name': 'Buyer $id', 'phone': '+201999999999', 'email': 'b$id@x.eg'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_admin_cr').path);
    await Hive.openBox('jeeran_prefs');
  });

  test('a call request is read with the number they asked to be called on', () {
    final r = CallRequestRow.fromJson(_row(1, 'new', verified: false));
    expect(r.phone, '+201000000001'); // the request's number, not the account's
    expect(r.phoneVerified, isFalse);
    expect(r.price, 5000000);
    expect(CallRequestRow.fromJson({'id': 2, 'created_at': 'x', 'user': {'phone': '+2011'}}).phone, '+2011'); // falls back to the account's
  });

  test('the admin notification for a call request opens the call requests', () {
    final n = InboxItem.fromJson({
      'id': 1,
      'is_read': false,
      'created_at': '2026-10-19T08:00:00.000Z',
      'notification': {'type': 'general', 'category': 'general', 'title_en': 'New call request', 'body_en': 'x', 'entity_id': 3},
    });
    expect(actionFor(n, ar: false)?.labelKey, 'notif.a_open_call_requests');
    final other = InboxItem.fromJson({
      'id': 2,
      'created_at': '2026-10-19T08:00:00.000Z',
      'notification': {'type': 'general', 'category': 'general', 'title_en': 'Welcome', 'body_en': 'x'},
    });
    expect(actionFor(other, ar: false), isNull);
  });

  testWidgets('admin call requests: tabs, mark contacted, close, note', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final rows = [_row(1, 'new'), _row(2, 'contacted', note: 'call back at 5')];
    final updates = <String>[];
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
            home: ValueListenableBuilder<Widget>(valueListenable: host, builder: (_, w, _) => KeyedSubtree(key: ObjectKey(w), child: w)),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 300));

    host.value = AdminCallRequestsPage(
      load: (status) async => [for (final r in rows) if (status.isEmpty || r['status'] == status) CallRequestRow.fromJson(r)],
      counts: () async => {
        'new': rows.where((r) => r['status'] == 'new').length,
        'contacted': rows.where((r) => r['status'] == 'contacted').length,
        'closed': rows.where((r) => r['status'] == 'closed').length,
        'all': rows.length,
      },
      update: (id, {status, note}) async {
        updates.add('$id:${status ?? ''}:${note ?? ''}');
        final r = rows.firstWhere((x) => x['id'] == id);
        if (status != null) r['status'] = status;
        if (note != null) r['admin_note'] = note;
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // New tab: one buyer, with the ways to reach them
    expect(find.byKey(const Key('cr-1')), findsOneWidget);
    expect(find.byKey(const Key('cr-2')), findsNothing);
    expect(find.text('Buyer 1'), findsOneWidget);
    expect(find.text('+201000000001'), findsOneWidget);
    expect(find.byKey(const Key('cr-call-1')), findsOneWidget);
    expect(find.byKey(const Key('cr-wa-1')), findsOneWidget);
    expect(find.textContaining('New (1)'), findsOneWidget);

    // mark contacted: it leaves the New tab and the counts follow
    await tester.tap(find.byKey(const Key('cr-contacted-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(updates, ['1:contacted:']);
    expect(find.byKey(const Key('cr-1')), findsNothing);
    expect(find.byKey(const Key('cr-empty')), findsOneWidget);

    // the Contacted tab has both, with the saved note
    await tester.tap(find.textContaining('Contacted'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('cr-1')), findsOneWidget);
    expect(find.byKey(const Key('cr-2')), findsOneWidget);
    expect(find.text('call back at 5'), findsOneWidget);

    // add a note
    await tester.tap(find.byKey(const Key('cr-note-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('cr-note-field')), 'asked for Friday');
    await tester.tap(find.byKey(const Key('cr-note-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(updates.last, '1::asked for Friday');
    expect(find.text('asked for Friday'), findsOneWidget);

    // close
    await tester.tap(find.byKey(const Key('cr-close-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(updates.last, '2:closed:');
    expect(find.byKey(const Key('cr-2')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
