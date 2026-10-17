import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/you/you_api.dart';
import 'package:jeeran_flutter/features/you/you_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _summary({
  String type = 'customer',
  Map<String, dynamic>? plan,
  int live = 0,
  int inReview = 0,
  int ads = 0,
  int unread = 0,
}) => {
  'user': {
    'id': 7,
    'name': 'Karim Al-Amin',
    'email': 'karim@jeeran.eg',
    'phone': '+201000000007',
    'user_type': type,
    'profile_picture': null,
  },
  'plan': plan,
  'listings': {'live': live, 'in_review': inReview, 'rejected': 0},
  'ai_ads': {'count': ads},
  'notifications': {'unread': unread, 'received_30d': 11, 'places_followed': 5},
};

class _FakeApi extends ApiClient {
  Map<String, dynamic> data;
  int calls = 0;
  _FakeApi(this.data);

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    calls++;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'success': true, 'data': data},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('summary parsing: plan maths and roles', () {
    final s = YouSummary.fromJson(
      _summary(
        type: 'customer',
        plan: {
          'name_en': 'Growth',
          'name_ar': 'نمو',
          'is_free': false,
          'used': 18,
          'total': 20,
          'remaining': 2,
          'end_date': '2026-09-14',
        },
      ),
    );
    expect(s.isAdmin, isFalse);
    expect(s.plan!.left, 2);
    expect(s.plan!.low, isTrue);
    expect(
      YouSummary.fromJson(_summary(plan: {'used': 5, 'total': 20})).plan!.low,
      isFalse,
    );
    expect(YouSummary.fromJson(_summary(type: 'super_admin')).isAdmin, isTrue);
    // a brand-new account has none of the optional blocks
    final bare = YouSummary.fromJson({
      'user': {'name': 'A'},
    });
    expect(bare.userType, 'customer');
    expect(bare.plan, isNull);
    expect(bare.live, 0);
  });

  group('screen', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_you_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      final lang = locale.languageCode;
      testWidgets('You in all four account states, in $lang', (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
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
                home: ValueListenableBuilder<Widget>(
                  valueListenable: host,
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

        Future<void> show(Map<String, dynamic> data) async {
          host.value = YouPage(api: YouApi(_FakeApi(data)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        // ── a customer: lists, sells, no "become a seller" step and no request banners
        await show(_summary(live: 18, inReview: 2, unread: 4));
        expect(tester.takeException(), isNull);
        expect(find.text('Karim Al-Amin'), findsOneWidget);
        expect(find.text('you.role_customer'.tr().toUpperCase()), findsOneWidget);
        expect(find.text('you.list_property'.tr()), findsOneWidget);
        expect(find.text('you.g_selling'.tr().toUpperCase()), findsOneWidget);
        expect(find.text('you.upsell_cta'.tr()), findsNothing);
        expect(find.text('you.pending_title'.tr()), findsNothing);
        expect(find.text('you.g_activity'.tr().toUpperCase()), findsOneWidget);
        // real notification figures, not estimates
        expect(find.textContaining('11'), findsWidgets);

        // ── a customer who still has an old plan from the server: no plan card; the Selling group and list button are there
        await show(
          _summary(
            type: 'customer',
            live: 18,
            inReview: 2,
            ads: 3,
            unread: 4,
            plan: {
              'name_en': 'Growth',
              'name_ar': 'نمو',
              'is_free': false,
              'used': 18,
              'total': 20,
              'remaining': 2,
              'end_date': '2027-09-14',
            },
          ),
        );
        expect(find.text('you.role_customer'.tr().toUpperCase()), findsOneWidget);
        // PACKAGES DISABLED: no plan card, no packages row, even when the server still sent a plan
        expect(find.text(lang == 'ar' ? 'نمو' : 'Growth'), findsNothing);
        expect(find.text('18 / 20'), findsNothing);
        expect(find.text('you.plan_upgrade'.tr()), findsNothing);
        expect(find.text('bottom_nav.packages'.tr()), findsNothing);
        expect(find.text('you.list_property'.tr()), findsOneWidget);
        expect(find.text('you.g_selling'.tr().toUpperCase()), findsOneWidget);
        expect(
          find.text('you.my_properties_meta'.tr(args: ['18', '2'])),
          findsOneWidget,
        );
        expect(find.text('more.ai_ads'.tr()), findsNothing); // no AI-ad entry on the profile
        expect(find.text('you.ads_meta'.plural(3)), findsNothing);
        expect(find.text('you.upsell_cta'.tr()), findsNothing);

        // plenty of room: the button reads Manage, no warning line
        await show(
          _summary(
            type: 'customer',
            plan: {
              'name_en': 'Pro',
              'name_ar': 'برو',
              'used': 4,
              'total': 20,
              'end_date': '2027-09-14',
            },
          ),
        );
        expect(find.text('you.plan_manage'.tr()), findsNothing);

        // always there: account rows and sign out can be reached
        expect(find.text('more.language'.tr()), findsOneWidget);
        expect(find.text('you.privacy'.tr()), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
