import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/error/exceptions.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:jeeran_flutter/features/notifications/presentation/pages/notifications_page.dart';
import 'package:jeeran_flutter/features/notifications/v2/notif_actions.dart';
import 'package:jeeran_flutter/features/notifications/v2/notif_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Anchored to local midnight so the Today / Yesterday / Earlier grouping never depends on the hour the tests run.
Duration get _sinceMidnightYesterday => DateTime.now().difference(
  DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).subtract(const Duration(hours: 1)),
);
Duration get _sinceLastWeek => DateTime.now().difference(
  DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).subtract(const Duration(days: 6)),
);

String _iso(Duration ago) =>
    DateTime.now().subtract(ago).toUtc().toIso8601String();

Map<String, dynamic> _row(
  int id,
  String type,
  String category,
  String title,
  String body, {
  bool read = false,
  Duration ago = const Duration(hours: 2),
  int? entity = 5,
}) => {
  'id': id,
  'is_read': read,
  'created_at': _iso(ago),
  'notification': {
    'id': id,
    'type': type,
    'category': category,
    'title_en': title,
    'title_ar': null,
    'body_en': body,
    'body_ar': null,
    'entity_id': entity,
    'created_at': _iso(ago),
  },
};

/// Shapes captured from the API.
class _FakeApi extends ApiClient {
  final calls = <String>[];
  bool failSaves = false;
  late List<Map<String, dynamic>> rows;
  Map<String, dynamic> settings;

  _FakeApi({List<Map<String, dynamic>>? rows, Map<String, dynamic>? settings})
    : settings = settings ?? _settings() {
    this.rows =
        rows ??
        [
          _row(
            1,
            'property',
            'listing',
            'Your listing is live',
            'Chalet was approved.',
            ago: Duration.zero,
          ),
          _row(
            2,
            'project',
            'place',
            'New phase',
            'Phase 4 — Marassi',
            ago: Duration.zero,
            entity: 4,
          ),
          _row(
            3,
            'subscription',
            'plan',
            '2 listings left on your plan',
            'Upgrade to keep publishing.',
            ago: Duration.zero,
          ),
          _row(
            4,
            'property',
            'listing',
            'Property Rejected',
            'Photos do not match the stated size.',
            read: true,
            ago: _sinceMidnightYesterday,
          ),
          _row(
            5,
            'general',
            'general',
            'Welcome to Jeeran',
            'Follow a developer.',
            read: true,
            ago: _sinceLastWeek,
            entity: null,
          ),
        ];
  }

  Response _ok(String path, dynamic body) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: body,
  );

  static String _chip(String type) => switch (type) {
    'property' => 'listings',
    'project' || 'developer' => 'projects',
    'subscription' => 'plans',
    'news' => 'news',
    'ad' => 'ads',
    _ => '',
  };

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    calls.add('GET $path ${queryParams ?? {}}');
    if (path == '/notifications') {
      final f = queryParams?['filter'];
      final shown = rows
          .where(
            (r) =>
                f == null ||
                _chip((r['notification'] as Map)['type'] as String) == f,
          )
          .toList();
      return _ok(path, {
        'success': true,
        'data': shown,
        'pagination': {
          'page': 1,
          'limit': 20,
          'total': shown.length,
          'pages': 1,
        },
      });
    }
    if (path == '/notifications/summary') {
      final unread = rows.where((r) => r['is_read'] == false).toList();
      final filters = <String, int>{
        'listings': 0,
        'projects': 0,
        'plans': 0,
        'news': 0,
        'ads': 0,
      };
      for (final r in unread) {
        final c = _chip((r['notification'] as Map)['type'] as String);
        if (c.isNotEmpty) filters[c] = filters[c]! + 1;
      }
      return _ok(path, {
        'success': true,
        'data': {'unread': unread.length, 'filters': filters},
      });
    }
    if (path == '/notifications/settings')
      return _ok(path, {'success': true, 'data': settings});
    return _ok(path, {'success': true, 'data': <dynamic>[]});
  }

  @override
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    calls.add('PATCH $path');
    if (path == '/notifications/read-all') {
      for (final r in rows) {
        r['is_read'] = true;
      }
    } else if (path.endsWith('/read')) {
      final id = int.parse(path.split('/')[2]);
      rows.firstWhere((r) => r['id'] == id)['is_read'] = true;
    }
    return _ok(path, {'success': true});
  }

  @override
  Future<Response> put(String path, {dynamic data}) async {
    calls.add('PUT $path $data');
    if (failSaves) throw const ServerException('nope');
    return _ok(path, {'success': true});
  }
}

Map<String, dynamic> _settings({bool places = true}) => {
  'categories': [
    {'id': 'saved', 'locked': false, 'enabled': true, 'received_30d': 3},
    {'id': 'plan', 'locked': true, 'enabled': true, 'received_30d': 1},
    {'id': 'listing', 'locked': false, 'enabled': true, 'received_30d': 6},
    {'id': 'news', 'locked': false, 'enabled': false, 'received_30d': 0},
    {'id': 'ai', 'locked': false, 'enabled': true, 'received_30d': 1},
  ],
  'compounds': places
      ? [
          {
            'id': 4,
            'name_ar': 'مراسي',
            'name_en': 'Marassi',
            'main_image': null,
            'alerts_enabled': true,
            'developer': {'name_ar': 'إعمار', 'name_en': 'Emaar Misr'},
            'last_update': {
              'title': 'Phase 4 released',
              'published_at': _iso(const Duration(hours: 5)),
              'is_fresh': true,
            },
          },
        ]
      : [],
  'developers': places
      ? [
          {
            'id': 2,
            'name_ar': 'إعمار',
            'name_en': 'Emaar Misr',
            'logo': null,
            'is_verified': true,
            'alerts_enabled': true,
            'last_update': null,
          },
        ]
      : [],
  'received_30d': 11,
  'places_followed': places ? 2 : 0,
  'places_on': places ? 2 : 0,
};

class _Host {
  final home = ValueNotifier<Widget>(const SizedBox());
}

Future<_Host> _boot(WidgetTester tester, Locale locale) async {
  tester.view.physicalSize = const Size(390 * 3, 2000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final host = _Host();
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
          home: ValueListenableBuilder<Widget>(
            valueListenable: host.home,
            builder: (_, page, _) =>
                KeyedSubtree(key: ObjectKey(page), child: page),
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

Future<void> _show(WidgetTester tester, _Host host, Widget page) async {
  host.home.value = page;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parsing and actions', () {
    test('an inbox row reads the receipt and its notification', () {
      final i = InboxItem.fromJson(
        _row(9, 'project', 'place', 'New phase', 'Phase 4', entity: 4),
      );
      expect(i.id, 9);
      expect(i.isRead, isFalse);
      expect(i.category, 'place');
      expect(i.entityId, 4);
      expect(i.asRead().isRead, isTrue);
      expect(i.title(true), 'New phase'); // no Arabic title → falls back
    });

    test('each kind of notification offers the right next step', () {
      InboxItem n(String type, String title, {int? entity = 5}) =>
          InboxItem.fromJson(_row(1, type, 'x', title, 'b', entity: entity));
      expect(
        actionFor(n('property', 'Property Approved'), ar: false)?.labelKey,
        'notif.a_view_listing',
      );
      expect(
        actionFor(n('property', 'Property Rejected'), ar: false)?.labelKey,
        'notif.a_read_reason',
      );
      expect(
        actionFor(n('project', 'New phase'), ar: false)?.labelKey,
        'notif.a_see_units',
      );
      expect(
        actionFor(n('developer', 'x'), ar: false)?.labelKey,
        'notif.a_view_developer',
      );
      expect(
        actionFor(n('subscription', 'x', entity: null), ar: false)?.labelKey,
        'notif.a_upgrade',
      );
      expect(
        actionFor(n('news', 'x'), ar: false)?.labelKey,
        'notif.a_open_news',
      );
      expect(actionFor(n('ad', 'x'), ar: false)?.labelKey, 'notif.a_open_ad');
      expect(
        actionFor(n('general', 'Welcome', entity: null), ar: false),
        isNull,
      );
      expect(
        actionFor(n('project', 'x', entity: null), ar: false),
        isNull,
      ); // nothing to open
    });

    test('settings: places, switches and counts', () {
      final s = NotifSettings.fromJson(_settings());
      expect(s.categories.map((c) => c.id), [
        'saved',
        'plan',
        'listing',
        'news',
        'ai',
      ]);
      expect(s.categories[1].locked, isTrue);
      expect(s.categories[3].enabled, isFalse);
      expect(s.placesFollowed, 2);
      expect(s.compounds.single.subtitleEn, 'Emaar Misr');
      expect(s.compounds.single.lastUpdate, 'Phase 4 released');
      expect(s.received30d, 11);
    });
  });

  group('screens', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_notif_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      final lang = locale.languageCode;

      testWidgets('inbox and settings in $lang', (tester) async {
        final host = await _boot(tester, locale);
        var api = _FakeApi();
        await _show(tester, host, NotificationsPage(api: NotifApi(api)));
        expect(tester.takeException(), isNull);

        // one chronological list under Today / Yesterday / Earlier, with the unread total
        expect(find.text('notif.unread_n'.plural(3)), findsOneWidget);
        expect(find.text('notif.day_today'.tr().toUpperCase()), findsOneWidget);
        expect(
          find.text('notif.day_yesterday'.tr().toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text('notif.day_earlier'.tr().toUpperCase()),
          findsOneWidget,
        );
        expect(find.text('Your listing is live'), findsOneWidget);
        expect(find.text('notif.a_view_listing'.tr()), findsOneWidget);
        expect(find.text('notif.a_see_units'.tr()), findsOneWidget);
        expect(find.text('notif.a_upgrade'.tr()), findsOneWidget);
        expect(find.text('notif.a_read_reason'.tr()), findsOneWidget);

        // filter chips carry their own unread counts and narrow the list from the server
        await tester.tap(find.text('notif.f_projects'.tr()));
        await _settle(tester);
        expect(api.calls.any((c) => c.contains('filter: projects')), isTrue);
        expect(find.text('New phase'), findsOneWidget);
        expect(find.text('Your listing is live'), findsNothing);
        await tester.tap(find.text('notif.f_all'.tr()));
        await _settle(tester);

        // tapping a row marks it read (header and chip counts drop)
        await tester.tap(
          find.text('Your listing is live'),
        ); // (its page can't open here: no service locator)
        await _settle(tester);
        expect(api.calls, contains('PATCH /notifications/1/read'));
        expect(find.text('notif.unread_n'.plural(2)), findsOneWidget);

        // the rejection opens its reason
        await tester.tap(find.text('notif.a_read_reason'.tr()));
        await _settle(tester);
        expect(find.text('notif.reason_title'.tr()), findsOneWidget);
        expect(find.text('Photos do not match the stated size.'), findsWidgets);
        await tester.tapAt(const Offset(10, 10));
        await _settle(tester);

        // mark all read
        await tester.tap(find.text('notif.mark_all'.tr()));
        await _settle(tester);
        expect(api.calls, contains('PATCH /notifications/read-all'));
        expect(find.text('notif.caught_up'.tr()), findsOneWidget);
        expect(find.text('notif.mark_all'.tr()), findsNothing);

        // empty inbox
        api = _FakeApi(rows: []);
        await _show(tester, host, NotificationsPage(api: NotifApi(api)));
        expect(find.text('notif.empty_title'.tr()), findsOneWidget);
        expect(find.text('notif.browse'.tr()), findsOneWidget);
        expect(tester.takeException(), isNull);

        // ── notification settings
        api = _FakeApi();
        await _show(tester, host, NotificationSettingsPage(api: NotifApi(api)));
        expect(tester.takeException(), isNull);

        // categories, the locked one marked, real counts in the header, places with their latest news
        expect(find.text('notif.cat_saved'.tr()), findsOneWidget);
        expect(find.text('notif.always'.tr().toUpperCase()), findsOneWidget);
        expect(
          find.textContaining('11'),
          findsWidgets,
        ); // 11 notifications in 30 days
        expect(find.text('Phase 4 released'), findsOneWidget);
        expect(find.text('notif.no_news'.tr()), findsOneWidget);

        // a category switch saves instantly
        final switches = find.byType(AnimatedContainer);
        expect(switches, findsWidgets);
        await tester.tap(find.text('notif.cat_news'.tr()).first);
        await _settle(tester);

        // "turn off all place alerts" mutes both, keeping them listed, and the button flips
        await tester.tap(find.text('notif.off_all'.tr()));
        await _settle(tester);
        expect(
          api.calls.any(
            (c) =>
                c.startsWith('PUT /user-subscriptions/alerts/all') &&
                c.contains('false'),
          ),
          isTrue,
        );
        expect(find.text('notif.muted'.tr()), findsNWidgets(2));
        expect(find.text('notif.on_all'.tr()), findsOneWidget);
        await tester.tap(find.text('notif.on_all'.tr()));
        await _settle(tester);
        expect(find.text('notif.muted'.tr()), findsNothing);

        // a failed save puts the switch back and says so
        api.failSaves = true;
        await tester.tap(find.text('notif.off_all'.tr()));
        await _settle(tester);
        expect(find.text('notif.muted'.tr()), findsNothing);
        expect(find.text('notif.save_failed'.tr()), findsOneWidget);

        // nothing followed yet
        api = _FakeApi(settings: _settings(places: false));
        await _show(tester, host, NotificationSettingsPage(api: NotifApi(api)));
        expect(find.text('notif.no_places_title'.tr()), findsOneWidget);
        expect(find.text('notif.off_all'.tr()), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
