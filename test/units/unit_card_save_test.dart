import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/di/injection_container.dart';
import 'package:jeeran_flutter/core/error/failures.dart';
import 'package:jeeran_flutter/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:jeeran_flutter/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeran_flutter/features/properties/domain/entities/property.dart';
import 'package:jeeran_flutter/features/units/presentation/unit_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements FavoritesRepository {
  final calls = <String>[];
  @override
  Future<Either<Failure, List<Property>>> getFavorites() async => const Right([]);
  @override
  Future<Either<Failure, void>> addFavorite(int propertyId) async {
    calls.add('add $propertyId');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeFavorite(int propertyId) async {
    calls.add('remove $propertyId');
    return const Right(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_unitsave_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  testWidgets('the heart saves and unsaves even where no FavoritesBloc is provided above the card', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await sl.reset();
    final repo = _Repo();
    sl.registerSingleton<FavoritesBloc>(FavoritesBloc(repository: repo));

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          // note: no BlocProvider anywhere above — this is the compound page's route
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: UnitCard(property: Property(id: 6685, titleEn: 'Apartment', titleAr: 'شقة', propertyType: 'apartment', price: '5400000', images: [])),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('unit-save-6685')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(repo.calls, ['add 6685']);
    expect(sl<FavoritesBloc>().isFavorited(6685), isTrue);

    await tester.tap(find.byKey(const Key('unit-save-6685')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(repo.calls, ['add 6685', 'remove 6685']);
    expect(tester.takeException(), isNull);
  });
}
