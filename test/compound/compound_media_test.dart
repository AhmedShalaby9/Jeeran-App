import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jeeran_flutter/features/compounds/data/compound_page_data.dart';
import 'package:jeeran_flutter/features/compounds/presentation/pages/compound_media_pages.dart';
import 'package:jeeran_flutter/features/compounds/presentation/widgets/compound_media.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _imgs = [
  'https://x/1.jpg',
  'https://x/2.jpg',
  'https://x/3.jpg',
  'https://x/4.jpg',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    Hive.init(Directory.systemTemp.createTempSync('jeeran_media_test').path);
    await Hive.openBox('jeeran_prefs');
  });

  test('the page data reads the plan and the pin; blank values are absent', () {
    final d = CompoundPageData.fromJson({
      'id': 1,
      'master_plan': ' https://x/p.jpg ',
      'latitude': '30.1162660',
      'longitude': 31.88,
    });
    expect(d.masterPlan, 'https://x/p.jpg');
    expect(d.hasPin, isTrue);
    final none = CompoundPageData.fromJson({
      'id': 1,
      'master_plan': '  ',
      'latitude': null,
      'longitude': '31.8',
    });
    expect(none.masterPlan, isNull);
    expect(none.hasPin, isFalse); // one coordinate is not a pin
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'tiles, map card, gallery and master plan viewers — ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        var plan = 0, gallery = 0;
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
                home: Scaffold(
                  body: ValueListenableBuilder<Widget>(
                    valueListenable: host,
                    builder: (_, w, _) => KeyedSubtree(
                      key: ObjectKey(w),
                      child: Builder(
                        builder: (ctx) => ListView(
                          padding: const EdgeInsets.all(20),
                          children: [w],
                        ),
                      ),
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
        Future<void> settle() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));
        }

        // ── tiles: both live
        host.value = MediaTiles(
          photos: 4,
          hasPlan: true,
          onPlan: () => plan++,
          onGallery: () => gallery++,
        );
        await settle();
        expect(find.text('compound.master_plan'.tr()), findsOneWidget);
        expect(find.text('compound.tap_to_zoom'.tr()), findsOneWidget);
        expect(find.text('compound.n_photos'.plural(4)), findsOneWidget);
        await tester.tap(find.byKey(const Key('tile-plan')));
        await tester.tap(find.byKey(const Key('tile-gallery')));
        expect([plan, gallery], [1, 1]);

        // ── no plan published / no photos: greyed and silent
        host.value = MediaTiles(
          photos: 0,
          hasPlan: false,
          onPlan: () => plan++,
          onGallery: () => gallery++,
        );
        await settle();
        expect(find.text('compound.not_published'.tr()), findsOneWidget);
        await tester.tap(find.byKey(const Key('tile-plan')));
        await tester.tap(find.byKey(const Key('tile-gallery')));
        expect([plan, gallery], [1, 1]);

        // ── the map card: area, cue, and a tap that does nothing
        host.value = const MapCard(area: 'New Cairo');
        await settle();
        expect(find.text('New Cairo'), findsOneWidget);
        expect(find.text('compound.directions'.tr()), findsOneWidget);
        await tester.tap(find.byKey(const Key('map-card')));
        await settle();
        expect(find.byKey(const Key('map-card')), findsOneWidget);
        expect(find.byType(CompoundGalleryPage), findsNothing);
        expect(tester.takeException(), isNull);

        // ── gallery viewer: every photo, then one large with a counter, then back
        late BuildContext ctx;
        host.value = Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox(height: 10);
          },
        );
        await settle();
        openGallery(ctx, name: 'Marassi', images: _imgs);
        await settle();
        expect(find.byType(CompoundGalleryPage), findsOneWidget);
        for (var i = 0; i < _imgs.length; i++) {
          expect(find.byKey(Key('gallery-photo-$i')), findsOneWidget);
        }
        await tester.tap(find.byKey(const Key('gallery-photo-2')));
        await settle();
        expect(find.byKey(const Key('photo-pager')), findsOneWidget);
        expect(find.text('3 / 4'), findsOneWidget);
        // the next photo is to the left in Arabic and to the right in English
        await tester.drag(
          find.byKey(const Key('photo-pager')),
          Offset(locale.languageCode == 'ar' ? 300 : -300, 0),
        );
        await settle();
        expect(find.text('4 / 4'), findsOneWidget);
        await tester.tap(find.byKey(const Key('viewer-close')));
        await settle();
        expect(find.byKey(const Key('photo-pager')), findsNothing);
        expect(find.byType(CompoundGalleryPage), findsOneWidget);
        await tester.tap(find.byKey(const Key('viewer-close')));
        await settle();
        expect(find.byType(CompoundGalleryPage), findsNothing);

        // ── master plan viewer: + and − zoom, never past the limits
        openMasterPlan(ctx, name: 'Marassi', url: 'https://x/plan.jpg');
        await settle();
        double scale() => tester
            .widget<InteractiveViewer>(find.byKey(const Key('plan-zoom')))
            .transformationController!
            .value
            .getMaxScaleOnAxis();
        expect(scale(), 1.0);
        await tester.tap(find.byKey(const Key('plan-zoom-in')));
        await settle();
        expect(scale(), closeTo(1.6, 0.01));
        for (var i = 0; i < 8; i++) {
          await tester.tap(find.byKey(const Key('plan-zoom-in')));
        }
        await settle();
        expect(scale(), closeTo(6.0, 0.01));
        for (var i = 0; i < 12; i++) {
          await tester.tap(find.byKey(const Key('plan-zoom-out')));
        }
        await settle();
        expect(scale(), closeTo(1.0, 0.01));
        await tester.tap(find.byKey(const Key('viewer-close')));
        await settle();
        expect(find.byKey(const Key('plan-zoom')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
