import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/profile/profile_api.dart';
import 'package:jeeran_flutter/features/profile/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _json(String type) => {
  'id': 4,
  'name': 'Karim Al-Amin',
  'email': 'karim@jeeran.eg',
  'phone': '+201004821937',
  'user_type': type,
  'profile_picture': null,
  'city': 'New Cairo',
  'preferred_language': null,
  'company_name': type == 'seller' ? 'Al-Amin Properties' : null,
  'bio': type == 'seller' ? 'Independent broker on the North Coast.' : null,
  'seller_verified': type == 'seller',
  'member_since': '2024-03-05T10:00:00.000Z',
  'live_listings': type == 'seller' ? 18 : null,
};

class _Client extends ApiClient {
  final Map<String, dynamic> profile;
  final puts = <Map<String, dynamic>>[];
  _Client(this.profile);

  Response _ok(String p, Map<String, dynamic> d) => Response(
    requestOptions: RequestOptions(path: p),
    statusCode: 200,
    data: {'success': true, 'data': d},
  );

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async => _ok(path, profile);

  @override
  Future<Response> putWithHeaders(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    puts.add(Map<String, dynamic>.from(data as Map));
    profile.addAll({'name': data['name'], 'city': data['city']});
    return _ok(path, profile);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parsing: seller extras are optional', () {
    final b = ProfileData.fromJson({'name': 'A', 'user_type': 'buyer'});
    expect(b.isSeller, isFalse);
    expect(b.company, isNull);
    expect(b.liveListings, isNull);
    final s = ProfileData.fromJson(_json('seller'));
    expect(s.isSeller, isTrue);
    expect(s.liveListings, 18);
    expect(s.sellerVerified, isTrue);
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_profile').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final lang = locale.languageCode;
    testWidgets('profile view and edit, seller then buyer, in $lang', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
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

      Future<_Client> show(String type) async {
        final c = _Client(_json(type));
        host.value = ProfilePage(api: ProfileApi(c));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        return c;
      }

      // ── seller: what buyers see
      var c = await show('seller');
      expect(tester.takeException(), isNull);
      expect(find.text('Karim Al-Amin'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(
        find.text('Independent broker on the North Coast.'),
        findsOneWidget,
      );
      expect(find.text('profile.note_seller'.tr()), findsOneWidget);

      // ── edit: Save is off until something changes
      await tester.tap(find.byKey(const Key('profile-edit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('f-company')), findsOneWidget);
      expect(find.text('profile.save'.tr()), findsOneWidget);
      await tester.enterText(find.byKey(const Key('f-name')), 'Karim Amin');
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-profile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.puts, hasLength(1));
      expect(c.puts.single['name'], 'Karim Amin');
      expect(c.puts.single['company_name'], 'Al-Amin Properties');
      // back on the profile, with the new name
      expect(find.text('Karim Amin'), findsOneWidget);

      // ── buyer: no seller block, no seller fields
      c = await show('buyer');
      expect(find.text('profile.note_buyer'.tr()), findsOneWidget);
      expect(find.text('profile.live_listings'.tr()), findsNothing);
      await tester.tap(find.byKey(const Key('profile-edit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('f-company')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
