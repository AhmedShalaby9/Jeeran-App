import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_brief_page.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';

import 'ad_studio_support.dart';

class _Api extends AdStudioApi {
  List<String> sentImages = [];
  (int, int)? scoredPixels;

  @override
  Future<String> upload(String path) async => 'https://cdn/${path.split('/').last}';

  @override
  Future<List<AdImageScore>> scoreImages(List<String> urls, {required AdBrief brief}) async {
    scoredPixels = brief.pixels;
    return [
      for (final u in urls)
        AdImageScore(
          url: u,
          status: u.contains('good') ? 'ok' : (u.contains('tiny') ? 'bad' : 'warn'),
          label: u.contains('good') ? 'good' : (u.contains('tiny') ? 'too_small' : 'blurry'),
        ),
    ];
  }

  @override
  Future<AdBriefResult> brief(AdBrief b) async {
    sentImages = List.of(b.images);
    throw Exception('stop here'); // the test only needs what was sent
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpAdStudioTests);

  testWidgets('uploads are scored: weak ones are skipped unless kept, too-small ones are never used', (t) async {
    t.view.physicalSize = const Size(390 * 3, 2000 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final api = _Api();
    await showPage(t, AdBriefPage(
      api: api,
      loadDevelopers: () async => const [],
      pickImages: () async => ['/x/good.jpg', '/x/soft.jpg', '/x/tiny.jpg'],
    ));
    await settle(t);

    await t.enterText(find.byKey(const Key('ad-summary')), 'Lagoon villas');
    await t.ensureVisible(find.byKey(const Key('ad-add-images')));
    await t.tap(find.byKey(const Key('ad-add-images')));
    await settle(t);
    await settle(t);

    expect(api.scoredPixels, (1200, 825)); // the default size: Explore banner
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Blurry'), findsOneWidget);
    expect(find.text('Too small'), findsOneWidget);
    expect(find.textContaining('too small for this size'), findsOneWidget);

    await t.tap(find.byKey(const Key('ad-continue')));
    await settle(t);
    expect(api.sentImages, ['https://cdn/good.jpg']); // only the good one

    // a bigger size means the same photos are scored again, against the new pixels
    await t.ensureVisible(find.byKey(const Key('ad-size-story')));
    await t.tap(find.byKey(const Key('ad-size-story')));
    await settle(t);
    expect(api.scoredPixels, (1080, 1920));

    // keep the blurry one; the too-small one stays out even when tapped
    await t.ensureVisible(find.byKey(const Key('ad-img-1')));
    await t.tap(find.byKey(const Key('ad-img-1')));
    await t.tap(find.byKey(const Key('ad-img-2')));
    await settle(t);
    expect(find.text('Kept'), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-continue')));
    await settle(t);
    expect(api.sentImages, ['https://cdn/good.jpg', 'https://cdn/soft.jpg']);
  });
}
