import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_export.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_results_page.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';

import 'ad_studio_support.dart';

AdDraft _story() => AdDraft.fromJson({
  'id': 7,
  'title': 'City Gate · Premium',
  'brief': {'slot': 'explore_top', 'size': 'story', 'width': 1080, 'height': 1920, 'sponsor': {'id': 24, 'name': 'Qatari Diar'}, 'target': {'type': 'compound', 'id': 644}, 'subject': {'en': 'City Gate', 'ar': 'سيتي جيت'}},
  'variations': [
    {'id': 'v1', 'tone': 'Premium', 'head_en': 'Calm family living', 'sub_en': 'Golf views', 'cta_en': 'See units', 'head_ar': 'حياة عائلية هادئة', 'sub_ar': 'إطلالة جولف', 'cta_ar': 'شاهد الوحدات', 'image_url': 'https://x/a.jpg', 'ai_image': true, 'facts': []},
    {'id': 'v2', 'tone': 'Offer-led', 'head_en': 'From EGP 11.2M', 'sub_en': 'Golf-view homes', 'cta_en': 'Explore', 'head_ar': 'من ١١٫٢ مليون', 'sub_ar': '', 'cta_ar': 'استكشف', 'image_url': 'https://x/b.jpg', 'ai_image': true, 'facts': []},
    {'id': 'v3', 'tone': 'Direct', 'head_en': 'City Gate', 'sub_en': '', 'cta_en': '', 'head_ar': 'سيتي جيت', 'sub_ar': '', 'cta_ar': '', 'image_url': 'https://x/c.jpg', 'ai_image': false, 'facts': []},
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpAdStudioTests);
  tearDown(() {
    AdExporter.renderOverride = null;
    AdExporter.saveOverride = null;
    AdExporter.shareOverride = null;
  });

  test('the draft remembers the pixels it was made at', () {
    final d = _story();
    expect((d.width, d.height), (1080, 1920));
    expect(AdDraft.fromJson({'id': 1}).width, 1200); // older drafts: the Explore banner size
  });

  testWidgets('Download renders the ad at its size and language, then saves it; Share sends the same picture', (t) async {
    t.view.physicalSize = const Size(390 * 3, 1900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final rendered = <AdArtworkData>[];
    final saved = <String>[];
    final shared = <String>[];
    AdExporter.renderOverride = (ctx, d) async {
      rendered.add(d);
      return Uint8List.fromList([1, 2, 3]);
    };
    AdExporter.saveOverride = (bytes, name) async => saved.add('$name:${bytes.length}');
    AdExporter.shareOverride = (bytes, name) async => shared.add(name);

    await showPage(t, AdResultsPage(api: AdStudioApi(), draft: _story()));
    await settle(t);
    await t.ensureVisible(find.byKey(const Key('ad-download')));

    expect(find.textContaining('1080 × 1920 px'), findsOneWidget); // the file is as big as the size picked
    await t.tap(find.byKey(const Key('ad-download')));
    await settle(t);
    expect(rendered.last.width, 1080);
    expect(rendered.last.height, 1920);
    expect(rendered.last.head, 'Calm family living'); // the app is in English
    expect(rendered.last.cta, 'See units');
    expect(saved.single, 'jeeran-ad-7-v1-1080x1920:3');

    // the Arabic version of the same ad
    await t.tap(find.byKey(const Key('ad-dl-ar')));
    await settle(t);
    await t.tap(find.byKey(const Key('ad-download')));
    await settle(t);
    expect(rendered.last.arabic, isTrue);
    expect(rendered.last.head, 'حياة عائلية هادئة');
    expect(saved.last, 'jeeran-ad-7-v1-1080x1920-ar:3');

    await t.tap(find.byKey(const Key('ad-share')));
    await settle(t);
    expect(shared.single, 'jeeran-ad-7-v1-1080x1920-ar');

    // "Download all": every ad of the set is saved, not only the picked one
    saved.clear();
    rendered.clear();
    await t.ensureVisible(find.byKey(const Key('ad-download-all')));
    expect(find.text('Download all 3'), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-download-all')));
    await settle(t);
    expect(saved, ['jeeran-ad-7-v1-1080x1920-ar:3', 'jeeran-ad-7-v2-1080x1920-ar:3', 'jeeran-ad-7-v3-1080x1920-ar:3']);
    expect(rendered.map((d) => d.head), ['حياة عائلية هادئة', 'من ١١٫٢ مليون', 'سيتي جيت']); // each in the chosen language
  });

  testWidgets('the artwork keeps the file’s proportions (390 wide, scaled up to the real size on export)', (t) async {
    Future<Size> sizeOf(int w, int h) async {
      await t.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SingleChildScrollView(child: AdArtwork(data: AdArtworkData(head: 'x', width: w, height: h)))))));
      return t.getSize(find.byType(AdArtwork));
    }

    final story = await sizeOf(1080, 1920);
    expect(story.width, 390);
    expect(story.height, closeTo(390 * 1920 / 1080, 0.5));
    final banner = await sizeOf(1200, 825);
    expect(banner.height, closeTo(390 * 825 / 1200, 0.5));
    final square = await sizeOf(1080, 1080);
    expect(square.height, 390);
  });
}
