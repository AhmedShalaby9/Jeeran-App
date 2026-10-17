import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/error/exceptions.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/follow/data/follow_service.dart';
import 'package:jeeran_flutter/features/follow/presentation/follow_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api extends ApiClient {
  final calls = <String>[];
  bool fail = false;

  Response _ok(String path) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'success': true},
  );

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    if (fail) throw const ServerException('down');
    calls.add('POST $path $data');
    return _ok(path);
  }

  @override
  Future<Response> put(String path, {dynamic data}) async {
    if (fail) throw const ServerException('down');
    calls.add('PUT $path $data');
    return _ok(path);
  }
}

FollowController _ctl(
  _Api api, {
  bool following = false,
  bool alerts = false,
}) => FollowController(
  service: FollowService(apiClient: api),
  type: FollowType.project,
  id: 4,
  name: 'Marassi',
  following: following,
  alertsOn: alerts,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('controller', () {
    test(
      'following turns every notification on; unfollowing drops them',
      () async {
        final api = _Api();
        final c = _ctl(api);
        expect(await c.toggleFollow(), isTrue);
        expect(c.following, isTrue);
        expect(c.alertsOn, isTrue);
        expect(await c.toggleFollow(), isTrue);
        expect(c.following, isFalse);
        expect(c.alertsOn, isFalse);
      },
    );

    test('every kind of news is on by default; each can be unticked but one always stays', () async {
      final api = _Api();
      final c = _ctl(api);
      expect(c.events, {'phase', 'launch', 'listing', 'news'});
      // not alerting yet: the choice is kept here until "Notify me"
      expect(await c.toggleEvent('news'), isTrue);
      expect(await c.toggleEvent('phase'), isTrue);
      expect(c.events, {'launch', 'listing'});
      expect(api.calls, isEmpty);
      await c.setAlerts(true);
      expect(api.calls.any((x) => x.startsWith('PUT') && x.contains('enabled: true') && x.contains('events: [launch, listing]')), isTrue);
      // alerts on: a change is saved at once
      api.calls.clear();
      await c.toggleEvent('launch');
      expect(c.events, {'listing'});
      expect(api.calls.single, contains('events: [listing]'));
      // the last one cannot go
      api.calls.clear();
      await c.toggleEvent('listing');
      expect(c.events, {'listing'});
      expect(api.calls, isEmpty);
      // a failed save puts it back
      api.fail = true;
      expect(await c.toggleEvent('news'), isFalse);
      expect(c.events, {'listing'});
      // a developer has no phases of its own
      final d = FollowController(service: FollowService(apiClient: api), type: FollowType.developer, id: 2, name: 'Emaar', following: false, alertsOn: false);
      expect(d.events, {'launch', 'listing', 'news'});
      // a saved choice comes back as it was
      final saved = FollowController(service: FollowService(apiClient: api), type: FollowType.project, id: 4, name: 'M', following: true, alertsOn: true, events: ['news']);
      expect(saved.events, {'news'});
    });

    test(
      'muting keeps the follow; "notify me" while not following follows first',
      () async {
        final api = _Api();
        final c = _ctl(api, following: true, alerts: true);
        expect(await c.setAlerts(false), isTrue);
        expect(c.following, isTrue);
        expect(c.alertsOn, isFalse);
        expect(api.calls.last, contains('PUT /user-subscriptions/alerts'));
        expect(api.calls.last, contains('enabled: false'));

        final fresh = _ctl(api);
        expect(await fresh.setAlerts(true), isTrue);
        expect(fresh.following, isTrue);
        expect(fresh.alertsOn, isTrue);
      },
    );

    test('a failed call puts everything back', () async {
      final api = _Api()..fail = true;
      final c = _ctl(api, following: true, alerts: true);
      expect(await c.setAlerts(false), isFalse);
      expect(c.following, isTrue);
      expect(c.alertsOn, isTrue);
      expect(await c.toggleFollow(), isFalse);
      expect(c.following, isTrue);
    });
  });

  group('screens', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_follow_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets(
        'follow button, bell, strip and sheet in ${locale.languageCode}',
        (tester) async {
          tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          final api = _Api();
          final c = _ctl(api);
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
                    body: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          FollowBar(c: c),
                          const SizedBox(height: 12),
                          AlertsStrip(c: c),
                        ],
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
          expect(tester.takeException(), isNull);

          // not following: a Follow button (not a heart) and an invitation to get alerts
          expect(find.text('follow.follow_compound'.tr()), findsOneWidget);
          expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
          expect(find.byKey(const Key('alerts-invite')), findsOneWidget);

          // Follow → Following, alerts on, receipt with the events
          await tester.tap(find.byKey(const Key('follow-button')));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('follow.following'.tr()), findsOneWidget);
          expect(find.byKey(const Key('alerts-on')), findsOneWidget);
          expect(find.text('follow.ev_phase'.tr()), findsOneWidget);

          // turn the alerts off: still following, now an invitation again
          await tester.tap(find.byKey(const Key('alerts-off')));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('follow.following'.tr()), findsOneWidget);
          expect(find.byKey(const Key('alerts-invite')), findsOneWidget);
          expect(
            find.text('follow.invite_muted'.tr(args: ['Marassi'])),
            findsOneWidget,
          );

          // the bell opens the disclosure; "Notify me" turns them back on
          await tester.tap(find.byKey(const Key('alert-bell')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          expect(
            find.text('follow.sheet_title'.tr(args: ['Marassi'])),
            findsOneWidget,
          );
          expect(find.text('follow.ev_listing'.tr()), findsWidgets);
          // everything is ticked to start; untick News, then Notify me
          await tester.tap(find.byKey(const Key('event-news')));
          await tester.pump(const Duration(milliseconds: 300));
          expect(c.events.contains('news'), isFalse);
          await tester.tap(find.byKey(const Key('notify-me')));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 500));
          expect(c.alertsOn, isTrue);
          expect(find.byKey(const Key('alerts-on')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
