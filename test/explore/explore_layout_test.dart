import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/explore/data/models/explore_data.dart';
import 'package:jeeran_flutter/features/explore/presentation/widgets/explore_banners.dart';
import 'package:jeeran_flutter/features/explore/presentation/widgets/explore_cards.dart';
import 'package:jeeran_flutter/features/explore/presentation/widgets/explore_widgets.dart';
import 'package:jeeran_flutter/features/news/v2/news_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'explore_data_test.dart' as fixture;

/// Renders the Explore building blocks at iPhone size in LTR and RTL.
/// Any RenderFlex overflow or build exception fails the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('Explore blocks lay out cleanly in ${locale.languageCode}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 3600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final d = ExploreData.fromJson(
        Map<String, dynamic>.from(fixture.homeFixture),
      );

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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    const ExploreGreeting(),
                    const SizedBox(height: 20),
                    ExploreSearchEntry(
                      onSearch: () {},
                      onAsk: () {},
                      onVoice: () {},
                    ),
                    const SizedBox(height: 20),
                    BannerRail(banners: d.topBanners),
                    const SizedBox(height: 20),
                    if (d.sellerRequest != null)
                      SellerStatusRow(
                        request: d.sellerRequest!,
                        onRejectedTap: () {},
                      ),
                    const SizedBox(height: 20),
                    QuickGrid(
                      tiles: [
                        for (final k in [
                          'chalets',
                          'villas',
                          'apartments',
                          'for_rent',
                        ])
                          QuickTile(
                            labelKey: 'explore.$k',
                            count: 2140,
                            tint: const Color(0x331A4A80),
                            onTap: () {},
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SectionHead(
                      eyebrow: 'explore.primary'.tr(),
                      title: 'explore.new_launches'.tr(),
                      onAction: () {},
                    ),
                    LaunchStrip(projects: d.launches),
                    const SizedBox(height: 20),
                    for (final p in d.featured)
                      ExplorePropertyCard(property: p),
                    const SizedBox(height: 20),
                    if (d.feedBanner != null)
                      InFeedBanner(banner: d.feedBanner!),
                    const SizedBox(height: 20),
                    NewsRail(news: d.news),
                    const SizedBox(height: 20),
                    TopCompoundsRail(projects: d.topCompounds),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      // translations load on a real async turn
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(BannerRail), findsOneWidget);
      expect(find.byType(QuickGrid), findsOneWidget);
      // ranked cards, #1 first, with the starting price
      expect(find.byKey(const Key('top-compound-1')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('explore.top_from'.tr(args: ['9.8M'])), findsOneWidget);
      // the news rail uses the same rows as the news list
      expect(find.byType(NewsRow), findsWidgets);
    });
  }
}
