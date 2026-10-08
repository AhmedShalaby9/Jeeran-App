import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/di/injection_container.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/core/services/app_settings_service.dart';
import 'package:jeeran_flutter/core/services/contact_call.dart';
import 'package:jeeran_flutter/features/compounds/data/compound_page_data.dart';
import 'package:jeeran_flutter/features/compounds/presentation/pages/compound_page.dart';
import 'package:jeeran_flutter/features/compounds/presentation/widgets/facility_icon.dart';
import 'package:jeeran_flutter/features/compounds/presentation/widgets/page_widgets.dart';
import 'package:jeeran_flutter/features/developers/data/developer_page_data.dart';
import 'package:jeeran_flutter/features/developers/presentation/pages/developer_page.dart';
import 'package:jeeran_flutter/features/follow/data/follow_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shapes captured from `GET /compounds/:id` and `GET /developers/:id` (X-Api-Version: 2).
Map<String, dynamic> _compound({List<Map<String, dynamic>> phases = const [], bool images = true}) => {
      'id': 3,
      'name_ar': 'مراسي',
      'name_en': 'Marassi',
      'desc_ar': 'وصف',
      'desc_en': 'A coastal compound.',
      // widget tests pass images: false — network images need platform plugins
      'main_image': images ? 'https://x/a.jpg' : null,
      'gallery': images ? ['https://x/a.jpg', 'https://x/b.jpg'] : [],
      'developer': {'id': 1, 'name_ar': 'إعمار', 'name_en': 'Emaar Misr', 'logo': null, 'is_verified': true},
      'area': {'id': 2, 'name_ar': 'الساحل الشمالي', 'name_en': 'North Coast'},
      'promotion': {'id': 8, 'type': 'launch', 'title_ar': 'إطلاق', 'title_en': 'Launch'},
      'status': 'new_launch',
      'min_price': 8950000,
      'units_count': 142,
      'followers_count': 12,
      'is_following': false,
      'latest_update': {'id': 4, 'title': 'Phase 4 released', 'is_fresh': true},
      'phases': phases,
      'unit_types': ['chalet', 'villa'],
      'size_min': 90,
      'size_max': 310,
      'delivered_since': 2015,
      'delivery_date': '2030-06-01',
      'finishing': 'fully_finished',
      'payment_options': ['cash', 'installments'],
      'down_payment_percent': '10.00',
      'installment_years': 8,
      'facilities_ar': ['نادي رياضي'],
      'facilities_en': ['Clubhouse', 'Swimming pools', 'Mystery thing'],
      'facts': [
        {'label_ar': 'مساحة الأرض', 'label_en': 'Land area', 'value_ar': '١٢٠ فدان', 'value_en': '120 feddan'},
      ],
    };

Map<String, dynamic> _developer({bool verified = true}) => {
      'id': 1,
      'name_ar': 'طلعت مصطفى',
      'name_en': 'Talaat Moustafa Group',
      'logo': null,
      'cover_image': null,
      'desc_en': 'A developer.',
      'address': 'Cairo',
      'founded_year': 1956,
      'stock_listing': 'EGX · TMGH',
      'delivered_units': 45000,
      'is_verified': verified,
      'is_following': false,
      'followers_count': 7,
      'trust_items': verified
          ? [
              {'title_en': 'Track record', 'title_ar': 'سجل', 'detail_en': 'Delivered on time', 'detail_ar': 'في الموعد'},
            ]
          : null,
      'stats': {'compounds_count': 2, 'units_count': 30, 'delivered_units': 45000, 'followers_count': 7},
      'compounds': [
        {
          'id': 3, 'name_ar': 'مراسي', 'name_en': 'Marassi', 'main_image': null, 'is_active': true,
          'area': {'name_ar': 'الساحل', 'name_en': 'North Coast'}, 'status': 'selling',
          'min_price': 5000000, 'units_count': 30,
        },
      ],
    };

class _FakeApi extends ApiClient {
  final Map<String, dynamic> compound;
  final Map<String, dynamic> developer;
  final List<String> calls = [];
  _FakeApi({required this.compound, required this.developer});

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async {
    calls.add('$path ${headers ?? {}}');
    Response ok(dynamic data) => Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: data);
    if (path.startsWith('/compounds/')) return ok({'success': true, 'data': compound});
    if (path.startsWith('/developers/')) return ok({'success': true, 'data': developer});
    if (path == '/properties') return ok({'success': true, 'data': []});
    return ok({'success': true, 'data': {'is_following': false}});
  }
}

/// easy_localization only loads a locale's strings once per test file, so each locale gets a
/// single app tree and the page under test is swapped inside it.
class _Host {
  final home = ValueNotifier<Widget>(const SizedBox());
}

Future<_Host> _boot(WidgetTester tester, Locale locale) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
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
            builder: (_, page, _) => KeyedSubtree(key: ObjectKey(page), child: page),
          ),
        ),
      ),
    ),
  );
  // translations load on a real async turn; do it before any page asks google_fonts for a font
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump(const Duration(milliseconds: 300));
  return host;
}

Future<void> _show(WidgetTester tester, _Host host, Widget page) async {
  host.home.value = page;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parsing', () {
    test('compound page: images de-duplicated, facts and payment parsed', () {
      final d = CompoundPageData.fromJson(_compound());
      expect(d.images, ['https://x/a.jpg', 'https://x/b.jpg']);
      expect(d.promotion?.type, 'launch');
      expect(d.developer?.isVerified, isTrue);
      expect(d.downPaymentPercent, 10);
      expect(d.facts.single.value.pick(false), '120 feddan');
      expect(d.facilities(false), hasLength(3));
      // falls back to the other language when one list is empty
      expect(CompoundPageData.fromJson({..._compound(), 'facilities_ar': []}).facilities(true), hasLength(3));
    });

    test('developer page: trust items are dropped for an unverified developer', () {
      expect(DeveloperPageData.fromJson(_developer()).trustItems, hasLength(1));
      // even if a stale payload carried them
      final leaked = {..._developer(verified: false), 'trust_items': _developer()['trust_items']};
      expect(DeveloperPageData.fromJson(leaked).trustItems, isEmpty);
    });

    test('phone number becomes a tel: link without punctuation', () {
      expect(ContactCall.telUri('+20 (100) 000-0000').toString(), 'tel:+201000000000');
      expect(ContactCall.telUri('  '), isNull);
      expect(ContactCall.telUri(null), isNull);
    });

    test('facility icons come from the wording, English or Arabic', () {
      expect(facilityIcon('Swimming pools'), Icons.pool_rounded);
      expect(facilityIcon('نادي رياضي'), Icons.groups_rounded);
      expect(facilityIcon('24/7 Security'), Icons.shield_outlined);
      expect(facilityIcon('Mystery thing'), Icons.check_circle_outline_rounded);
    });
  });

  group('pages', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_compound_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    late _FakeApi api;
    Future<void> setUpApi({Map<String, dynamic>? compound, Map<String, dynamic>? developer, String? phone}) async {
      await sl.reset();
      api = _FakeApi(compound: compound ?? _compound(images: false), developer: developer ?? _developer());
      sl.registerSingleton<ApiClient>(api);
      sl.registerSingleton<FollowService>(FollowService(apiClient: api));
      AppSettingsService.instance.settings = AppSettings(contactPhone: phone);
    }

    for (final locale in const [Locale('en'), Locale('ar')]) {
      final lang = locale.languageCode;

      testWidgets('compound and developer pages in $lang', (tester) async {
        final host = await _boot(tester, locale);

        // ── compound: lays out, asks for API v2, call button present
        await setUpApi(phone: '+201000000000');
        await _show(tester, host, const CompoundPage(compoundId: 3));
        expect(tester.takeException(), isNull);
        expect(api.calls.first, contains('X-Api-Version'));
        expect(find.text(lang == 'ar' ? 'مراسي' : 'Marassi'), findsWidgets);
        expect(find.byType(CallBar), findsOneWidget);
        expect(find.byIcon(Icons.call_rounded), findsOneWidget);

        // ── Phases tab is never hidden: empty state
        await tester.tap(find.text('compound.tab_phases'.tr()));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('compound.phases_empty_title'.tr()), findsOneWidget);

        // ── About tab: computed rows, custom facts, facilities
        await tester.tap(find.text('compound.tab_about'.tr()));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('compound.row_payment'.tr()), findsOneWidget);
        expect(find.text(lang == 'ar' ? 'مساحة الأرض' : 'Land area'), findsOneWidget);
        expect(find.byIcon(lang == 'ar' ? Icons.groups_rounded : Icons.pool_rounded), findsOneWidget);

        // ── Phases tab with data: status label + count
        await setUpApi(
          phone: '+201000000000',
          compound: _compound(images: false, phases: [
            {
              'id': 1, 'name_ar': 'مارينا', 'name_en': 'Marina Rise', 'delivery_label_ar': 'تسليم 2028',
              'delivery_label_en': 'Delivery 2028', 'available_count': 12, 'min_price': 9000000, 'status': 'selling_now',
            },
            {'id': 2, 'name_ar': 'ب', 'name_en': 'Bayside', 'available_count': 0, 'status': 'sold_out'},
          ]),
        );
        await _show(tester, host, const CompoundPage(compoundId: 3));
        await tester.tap(find.text('compound.tab_phases'.tr()));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('compound.phase_selling_now'.tr()), findsOneWidget);
        expect(find.text('compound.phase_sold_out'.tr()), findsOneWidget);

        // ── developer: trust block only for verified
        await setUpApi(phone: '+201000000000');
        await _show(tester, host, const DeveloperPage(developerId: 1));
        await tester.tap(find.text('developer.tab_about'.tr()));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('developer.why_title'.tr()), findsOneWidget);
        expect(find.text('developer.call_us'.tr()), findsOneWidget);

        await setUpApi(developer: _developer(verified: false));
        await _show(tester, host, const DeveloperPage(developerId: 1));
        await tester.tap(find.text('developer.tab_about'.tr()));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('developer.why_title'.tr()), findsNothing);
        // ── no contact phone saved: no call buttons
        expect(find.byIcon(Icons.call_rounded), findsNothing);
        await setUpApi();
        await _show(tester, host, const CompoundPage(compoundId: 3));
        expect(find.byIcon(Icons.call_rounded), findsNothing);
      });
    }
  });
}
