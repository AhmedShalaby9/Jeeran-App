import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/di/injection_container.dart';
import 'package:jeeran_flutter/core/error/exceptions.dart';
import 'package:jeeran_flutter/core/error/failures.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:jeeran_flutter/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeran_flutter/features/properties/data/models/property_model.dart';
import 'package:jeeran_flutter/features/properties/data/property_page_data.dart';
import 'package:jeeran_flutter/features/properties/domain/entities/property.dart';
import 'package:jeeran_flutter/features/properties/presentation/pages/property_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shape captured from `GET /properties/:id` with X-Api-Version: 2.
Map<String, dynamic> _payload({String? whatsapp = '+201111111111', String? mobile = '+202222222222', bool extras = true}) => {
      'id': 10,
      'title_ar': 'شالية بحر',
      'title_en': 'Sea view chalet',
      'content_ar': 'وصف',
      'content_en': 'Front-row chalet in Bayside.',
      'property_type': 'chalet',
      'property_status': 'for_sale',
      'listing_type': 'primary',
      'price': '12400000.00',
      'price_per_m2': 67391,
      'size': '184.00',
      'bedrooms': 3,
      'bathrooms': 2,
      'images': <String>[],
      'is_featured': true,
      'garden_size': extras ? '46.00' : null,
      'level_en': extras ? 'Ground' : null,
      'level_ar': extras ? 'أرضي' : null,
      'maintenance_en': extras ? '8% on delivery' : null,
      'floor_plan': null,
      'reference_code': 'MAR-00010',
      'published_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      'agent_name': 'Reem Al-Sayed',
      'agent_mobile': mobile,
      'agent_whatsapp': whatsapp,
      'seller_verified': true,
      'is_favorited': false,
      'phase': {'id': 1, 'name_ar': 'بايسايد', 'name_en': 'Bayside'},
      'compound': {
        'id': 4,
        'name_ar': 'مراسي',
        'name_en': 'Marassi',
        'main_image': null,
        'developer_id': 2,
        'area': {'id': 1, 'name_ar': 'الساحل الشمالي', 'name_en': 'North Coast'},
        'developer': {'id': 2, 'name_ar': 'إعمار', 'name_en': 'Emaar Misr', 'logo': null, 'is_verified': true},
      },
      'chain': {
        'compound': {'units_count': 142, 'phases_count': 4},
        'developer': {'compounds_count': 4, 'units_count': 612},
      },
      'effective': {
        'delivery_date': '2024-01-01',
        'is_ready': true,
        'finishing': 'fully_finished',
        'payment_options': ['installments', 'cash'],
        'down_payment_percent': 10,
        'installment_years': 8,
        'amenities': ['sea_view', 'private_garden'],
      },
    };

class _FakeApi extends ApiClient {
  Map<String, dynamic> property;
  final calls = <String>[];
  bool limited = false;
  _FakeApi(this.property);

  Response _ok(String path, dynamic body) => Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: body);

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async {
    calls.add('GET $path');
    if (path == '/properties/10') return _ok(path, {'success': true, 'data': property});
    if (path == '/properties/10/similar') return _ok(path, {'success': true, 'data': <dynamic>[]});
    if (path == '/chat/scope') {
      return _ok(path, {
        'success': true,
        'data': {
          'type': queryParams?['type'],
          'id': queryParams?['id'],
          'name': 'Sea view chalet',
          'source': 'This listing · 4 units at Marassi · prices live today',
          'prompts': ['Is this priced fairly for the compound?', 'What are the payment options?'],
          'limit': {'limit': 30, 'remaining': 30},
        },
      });
    }
    return _ok(path, {'success': true, 'data': <dynamic>[]});
  }

  @override
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    calls.add('POST $path ${data ?? ''}');
    if (path == '/chat/sessions') return _ok(path, {'success': true, 'data': {'id': 7}});
    if (path == '/chat/sessions/7/messages') {
      if (limited) throw const ServerException('limit', 'ai_limit', 600);
      return _ok(path, {
        'success': true,
        'data': {
          'reply': 'Slightly above the middle.',
          'references': {
            'facts': [
              {'label': 'This unit, per m²', 'value': '67,391'},
              {'label': 'Compound average', 'value': '63,400'},
            ],
          },
          'limit': {'limit': 30, 'remaining': 4},
        },
      });
    }
    return _ok(path, {'success': true, 'data': <dynamic>{}});
  }

  @override
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    calls.add('PATCH $path');
    return _ok(path, {'success': true, 'data': {'scope_type': null}});
  }
}

class _FakeFavorites implements FavoritesRepository {
  @override
  Future<Either<Failure, List<Property>>> getFavorites() async => const Right([]);
  @override
  Future<Either<Failure, void>> addFavorite(int propertyId) async => const Right(null);
  @override
  Future<Either<Failure, void>> removeFavorite(int propertyId) async => const Right(null);
}

/// easy_localization loads each locale once per test file, so one app tree per locale.
class _Host {
  final home = ValueNotifier<Widget>(const SizedBox());
}

Future<_Host> _boot(WidgetTester tester, Locale locale) async {
  tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
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

Property get _listItem => PropertyModel.fromJson({
      'id': 10, 'title_ar': 'شالية بحر', 'title_en': 'Sea view chalet', 'images': <String>[], 'price': '12400000.00',
      'bedrooms': 3, 'bathrooms': 2, 'size': '184.00',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parsing', () {
    test('page data reads extras, chain and inherited attributes', () {
      final d = PropertyPageData.fromJson(_payload());
      expect(d.pricePerM2, 67391);
      expect(d.garden, 46);
      expect(d.compound?.unitsCount, 142);
      expect(d.compound?.phasesCount, 4);
      expect(d.developer?.unitsCount, 612);
      expect(d.isReady, isTrue);
      expect(d.paymentOptions, ['installments', 'cash']);
      expect(d.referenceCode, 'MAR-00010');
      expect(d.gallery, isEmpty);
    });

    test('empty extras stay empty, so the page hides them', () {
      final d = PropertyPageData.fromJson(_payload(extras: false));
      expect(d.garden, isNull);
      expect(d.level.isEmpty, isTrue);
      expect(d.maintenance.isEmpty, isTrue);
    });

    test('floor plan goes last in the gallery', () {
      final d = PropertyPageData.fromJson({..._payload(), 'images': ['a.jpg', 'b.jpg'], 'floor_plan': 'plan.png'});
      expect(d.gallery, ['a.jpg', 'b.jpg', 'plan.png']);
    });
  });

  group('screens', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_property_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    Future<_FakeApi> setUpApi(Map<String, dynamic> payload) async {
      await sl.reset();
      final api = _FakeApi(payload);
      sl.registerSingleton<ApiClient>(api);
      sl.registerSingleton<FavoritesBloc>(FavoritesBloc(repository: _FakeFavorites()));
      return api;
    }

    for (final locale in const [Locale('en'), Locale('ar')]) {
      final lang = locale.languageCode;
      testWidgets('property page and its Ask sheet in $lang', (tester) async {
        final host = await _boot(tester, locale);

        // ── the page: no instalment figure, no map, no share, real contact buttons
        var api = await setUpApi(_payload());
        await _show(tester, host, PropertyDetailsPage(property: _listItem));
        expect(tester.takeException(), isNull);
        expect(api.calls.first, 'GET /properties/10');
        expect(find.text(lang == 'ar' ? 'شالية بحر' : 'Sea view chalet'), findsWidgets);
        expect(find.textContaining('67,391'), findsOneWidget); // per m²
        expect(find.textContaining('MAR-00010'), findsWidgets); // facts row + footer
        expect(find.text('prop.f_garden'.tr()), findsOneWidget);
        expect(find.text('prop.f_maintenance'.tr()), findsOneWidget);
        expect(find.byIcon(Icons.share_outlined), findsNothing);
        expect(find.byIcon(Icons.map_outlined), findsNothing);
        expect(find.textContaining('/ month'), findsNothing);
        expect(find.text('prop.call_seller'.tr()), findsOneWidget);
        expect(find.text('prop.message'.tr()), findsOneWidget);

        // ── the chain links up to the compound and the developer
        expect(find.text(lang == 'ar' ? 'مراسي' : 'Marassi'), findsWidgets);
        expect(find.text('prop.compound'.tr().toUpperCase()), findsOneWidget);
        expect(find.text('prop.developer'.tr().toUpperCase()), findsOneWidget);

        // ── the Ask card shows the server's suggestions
        expect(find.text('Is this priced fairly for the compound?'), findsOneWidget);
        expect(api.calls.any((c) => c == 'GET /chat/scope'), isTrue);

        // ── a number missing hides its button
        api = await setUpApi(_payload(whatsapp: null, extras: false));
        await _show(tester, host, PropertyDetailsPage(property: _listItem));
        expect(find.text('prop.message'.tr()), findsNothing);
        expect(find.text('prop.call_seller'.tr()), findsOneWidget);
        expect(find.text('prop.f_garden'.tr()), findsNothing);

        api = await setUpApi(_payload(whatsapp: null, mobile: null));
        await _show(tester, host, PropertyDetailsPage(property: _listItem));
        expect(find.text('prop.call_seller'.tr()), findsNothing);
        expect(find.text('prop.message'.tr()), findsNothing);

        // ── the Ask sheet: tap a suggestion → scoped session, answer, fact table
        api = await setUpApi(_payload());
        await _show(tester, host, PropertyDetailsPage(property: _listItem));
        await tester.tap(find.text('ask.open_property'.tr()));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(find.text('ask.pill_only'.tr(args: [lang == 'ar' ? 'شالية بحر' : 'Sea view chalet'])), findsOneWidget);
        expect(find.text('ask.widen'.tr()), findsOneWidget);
        await tester.tap(find.text('What are the payment options?').last);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(api.calls.any((c) => c.startsWith('POST /chat/sessions') && c.contains('scope_type: property') && c.contains('scope_id: 10')), isTrue);
        expect(find.text('Slightly above the middle.'), findsOneWidget);
        expect(find.text('This unit, per m²'), findsOneWidget);
        expect(find.text('67,391'), findsOneWidget);
        expect(find.text('ask.left'.plural(4)), findsOneWidget); // 4 of 30 left → warn

        // ── Widen tells the server and changes the pill
        await tester.tap(find.text('ask.widen'.tr()));
        await tester.pump(const Duration(milliseconds: 300));
        expect(api.calls, contains('PATCH /chat/sessions/7/scope'));
        expect(find.text('ask.pill_wide'.tr()), findsOneWidget);

        // ── over the hourly limit: a clear message, not a crash
        api.limited = true;
        await tester.enterText(find.byType(TextField).last, 'one more');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('ask.limit_reached'.tr(args: ['10'])), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
