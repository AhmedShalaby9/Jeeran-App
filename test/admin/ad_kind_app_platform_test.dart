// Social post defaults to Instagram and each platform maps to its own pixel size (see
// ad_kind_app_format_test.dart for the Banner/News cases).
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

  testWidgets('app ad: Social post defaults to Instagram (-> post, 1080x1350)', (t) async {
    t.view.physicalSize = const Size(390 * 3, 2600 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final api = _FakeApi();
    await showPage(t, AdBriefPage(api: api, pickImages: () async => ['/tmp/logo.png']));
    await settle(t);

    await t.enterText(find.byKey(const Key('ad-summary')), 'Zero commission, new logo, social post for the app');
    await t.tap(find.byKey(const Key('ad-kind-app')));
    await settle(t);
    await t.tap(find.byKey(const Key('ad-fmt-social')));
    await settle(t);

    expect(find.byKey(const Key('ad-plat-instagram')), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-add-images')));
    await settle(t);
    await t.tap(find.byKey(const Key('ad-continue')));
    await settle(t);
    expect(api.briefJson!['size'], 'post'); // Instagram -> post (1080x1350)
  });
}
