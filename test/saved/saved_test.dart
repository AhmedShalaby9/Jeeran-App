import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/saved/data/models/saved_models.dart';
import 'package:jeeran_flutter/features/saved/presentation/widgets/saved_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shapes captured from the backend (`GET /favorites`, `/saved/compounds`, `/saved/developers`).
const _listing = {
  'id': 7, 'title_ar': 'شالية', 'title_en': 'Chalet', 'images': ['https://x/a.jpg'], 'price': '12400000.00',
  'bedrooms': 3, 'bathrooms': 2, 'size': '184.00', 'is_favorited': true,
  'price_change': -400000, 'availability': 'available',
  'project': {
    'id': 1, 'name_ar': 'مراسي', 'name_en': 'Marassi', 'gallery': [], 'features': [], 'is_active': true,
    'developer': {'id': 1, 'name_ar': 'إعمار', 'name_en': 'Emaar Misr'},
  },
};
const _sold = {'id': 9, 'title_ar': 'شقة', 'title_en': 'Apt', 'images': [], 'price': '6300000.00', 'price_change': 0, 'availability': 'sold'};
const _compound = {
  'id': 1, 'name_ar': 'مراسي', 'name_en': 'Marassi', 'gallery': [], 'features': [], 'is_active': true,
  'state': 'north_coast', 'min_price': 8950000, 'units_count': 142,
  'developer': {'id': 1, 'name_ar': 'إعمار', 'name_en': 'Emaar Misr'},
  'latest_update': {'id': 4, 'title': 'Phase 4 released — 18 units', 'is_fresh': true}, 'is_fresh': true,
};
const _developer = {
  'id': 1, 'name_ar': 'طلعت مصطفى', 'name_en': 'Talaat Moustafa Group', 'logo': null, 'is_verified': true,
  'projects_count': 9, 'listings_count': 1240,
  'latest_update': {'id': 5, 'title': 'Launched South Med phase 2', 'is_fresh': false},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('models', () {
    test('a price drop is only a drop while the listing is still available', () {
      expect(SavedListing.fromJson(Map<String, dynamic>.from(_listing)).hasDropped, isTrue);
      final sold = SavedListing.fromJson(Map<String, dynamic>.from(_sold));
      expect(sold.isSold, isTrue);
      expect(sold.isGone, isTrue);
      expect(sold.hasDropped, isFalse);
    });

    test('compound keeps developer, area, price and its latest update', () {
      final c = SavedCompound.fromJson(Map<String, dynamic>.from(_compound));
      expect(c.project.developer?.name, 'Emaar Misr');
      expect(c.project.areaLabel, 'North Coast');
      expect(c.project.minPrice, 8950000);
      expect(c.project.unitsCount, 142);
      expect(c.isFresh, isTrue);
      expect(c.latestUpdate?.title, 'Phase 4 released — 18 units');
    });

    test('developer monogram: initials of up to three words', () {
      expect(SavedDeveloper.fromJson(Map<String, dynamic>.from(_developer)).short, 'TMG');
      expect(const SavedDeveloper(id: 2, nameAr: '', nameEn: 'Emaar Misr').short, 'EM');
      expect(const SavedDeveloper(id: 3, nameAr: '', nameEn: 'Palm').short, 'PA');
    });

    test('counts parse and copyWith keeps the summary numbers', () {
      final c = SavedCounts.fromJson({
        'listings': 4, 'compounds': 3, 'developers': 4, 'price_drops': 1, 'sold': 1,
        'unavailable': 0, 'fresh_compounds': 1, 'developer_projects': 24,
      });
      expect(c.copyWith(listings: 3).priceDrops, 1);
      expect(c.copyWith(listings: 3).listings, 3);
    });
  });

  group('layout', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      Hive.init(Directory.systemTemp.createTempSync('jeeran_saved_test').path);
      await Hive.openBox('jeeran_prefs');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets('Saved rows lay out cleanly in ${locale.languageCode}', (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        void noop() {}
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
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      SavedListingRow(item: SavedListing.fromJson(Map<String, dynamic>.from(_listing)), onOpen: noop, onRemove: noop),
                      const SizedBox(height: 10),
                      SavedListingRow(item: SavedListing.fromJson(Map<String, dynamic>.from(_sold)), onOpen: noop, onRemove: noop),
                      const SizedBox(height: 10),
                      SavedCompoundCard(
                        item: SavedCompound.fromJson(Map<String, dynamic>.from(_compound)),
                        onOpen: noop, onUnfollow: noop, onOpenUpdate: noop,
                      ),
                      const SizedBox(height: 10),
                      SavedDeveloperRow(
                        item: SavedDeveloper.fromJson(Map<String, dynamic>.from(_developer)),
                        onOpen: noop, onUnfollow: noop, onOpenUpdate: noop,
                      ),
                      const SavedEmptyState(
                        titleKey: 'saved.empty_listings_title',
                        subKey: 'saved.empty_listings_sub',
                        icon: Icons.bookmark_border_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byType(SavedCompoundCard), findsOneWidget);
      });
    }
  });
}
