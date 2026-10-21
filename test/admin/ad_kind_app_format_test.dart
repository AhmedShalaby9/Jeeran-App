// An app ad picks where it runs by name (Banner / News / Social post → Instagram/WhatsApp/Facebook)
// instead of the raw pixel-size grid a place ad uses. Each choice just sets AdBrief.size underneath,
// so the backend contract and existing size validation are unchanged.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_brief_page.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';

import 'ad_studio_support.dart';

class _FakeApi extends AdStudioApi {
  Map<String, dynamic>? briefJson;

  @override
  Future<String> upload(String path) async => 'https://x/logo.png';

  @override
  Future<List<AdImageScore>> scoreImages(List<String> urls, {required AdBrief brief}) async =>
      [for (final u in urls) AdImageScore(url: u, status: 'ok', label: 'good')];

  @override
  Future<AdBriefResult> brief(AdBrief b) async {
    briefJson = b.toJson();
    return AdBriefResult.fromJson({
      'understood': {'audience': null, 'angle': null, 'feel': null, 'must_show': null},
      'facts': [],
      'images': [],
      'subject': {'en': 'Jeeran', 'ar': 'جيران'},
      'sponsor': null,
      'target': {'type': 'app', 'id': null},
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpAdStudioTests);

  testWidgets('app ad: Banner/News/Social(+platform) each set the right pixel size, defaulting to News', (t) async {
    t.view.physicalSize = const Size(390 * 3, 2600 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final api = _FakeApi();
    await showPage(t, AdBriefPage(api: api, pickImages: () async => ['/tmp/logo.png']));
    await settle(t);

    await t.enterText(find.byKey(const Key('ad-summary')), 'Zero commission, new logo, social post for the app');
    await t.tap(find.byKey(const Key('ad-kind-app')));
    await settle(t);

    // the pixel-size grid is gone; the format picker is there instead, defaulting to News (-> top, 1200x825)
    expect(find.byKey(const Key('ad-size-top')), findsNothing);
    expect(find.byKey(const Key('ad-fmt-news')), findsOneWidget);
    expect(find.byKey(const Key('ad-plat-instagram')), findsNothing); // no platform row until Social is picked

    await t.tap(find.byKey(const Key('ad-fmt-banner')));
    await settle(t);

    await t.tap(find.byKey(const Key('ad-add-images')));
    await settle(t);
    await t.tap(find.byKey(const Key('ad-continue')));
    await settle(t);
    expect(api.briefJson!['size'], 'feed'); // Banner -> feed (1200x600)
  });
}
