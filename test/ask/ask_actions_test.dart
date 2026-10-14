import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/core/di/injection_container.dart';
import 'package:jeeran_flutter/core/error/failures.dart';
import 'package:jeeran_flutter/core/network/api_client.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_api.dart';
import 'package:jeeran_flutter/features/ai_chat/ask/ask_widgets.dart';
import 'package:jeeran_flutter/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:jeeran_flutter/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeran_flutter/features/follow/data/follow_service.dart';
import 'package:jeeran_flutter/features/properties/domain/entities/property.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Follow extends FollowService {
  final calls = <String>[];
  _Follow() : super(apiClient: ApiClient());
  @override
  Future<void> follow(FollowType type, int id) async => calls.add('follow ${type.name} $id');
  @override
  Future<void> unfollow(FollowType type, int id) async => calls.add('unfollow ${type.name} $id');
}

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

final _refs = AskRefs.fromJson({
  'actions': [
    {'action': 'follow', 'changed': true, 'entity_type': 'compound', 'entity_id': 212, 'name_ar': 'ميفيدا', 'name_en': 'Mivida'},
    {'action': 'save', 'changed': true, 'entity_type': 'property', 'entity_id': 528, 'name_ar': 'بنتهاوس', 'name_en': 'Penthouse in Peerage Residence'},
    {'action': 'follow', 'changed': false, 'entity_type': 'developer', 'entity_id': 262, 'name_ar': 'زايا', 'name_en': 'Zaya Development'},
    {'bad': true},
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_askact_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  test('actions are parsed from the reply; broken rows are dropped', () {
    expect(_refs.actions, hasLength(3));
    expect(_refs.actions.first.entityType, 'compound');
    expect(_refs.actions[2].changed, isFalse);
    expect(_refs.actions.first.name(true), 'ميفيدا');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    final ar = locale.languageCode == 'ar';

    testWidgets('what the assistant did is shown, and Undo reverses it — ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await sl.reset();
      final follow = _Follow();
      final repo = _Repo();
      sl.registerSingleton<FollowService>(follow);
      sl.registerSingleton<FavoritesBloc>(FavoritesBloc(repository: repo));

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
              home: Scaffold(body: SingleChildScrollView(child: AskActionChips(actions: _refs.actions))),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('ask-action-0')), findsOneWidget);
      expect(find.text('concierge.act_follow'.tr(namedArgs: {'name': ar ? 'ميفيدا' : 'Mivida'})), findsOneWidget);
      expect(find.text('concierge.act_save'.tr(namedArgs: {'name': ar ? 'بنتهاوس' : 'Penthouse in Peerage Residence'})), findsOneWidget);
      // it was already followed: said so, and nothing to undo
      expect(find.text('concierge.act_follow_same'.tr(namedArgs: {'name': ar ? 'زايا' : 'Zaya Development'})), findsOneWidget);
      expect(find.byKey(const Key('ask-undo-2')), findsNothing);
      // the saved heart follows what the assistant did
      expect(sl<FavoritesBloc>().isFavorited(528), isTrue);

      // Undo of the follow unfollows exactly that compound
      await tester.tap(find.byKey(const Key('ask-undo-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(follow.calls, ['unfollow project 212']);
      expect(find.text('concierge.act_undone'.tr()), findsOneWidget);
      expect(find.byKey(const Key('ask-undo-0')), findsNothing);

      // Undo of the save removes it from Saved
      await tester.tap(find.byKey(const Key('ask-undo-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(sl<FavoritesBloc>().isFavorited(528), isFalse);
      expect(repo.calls, contains('remove 528'));
      expect(tester.takeException(), isNull);
    });
  }
}
