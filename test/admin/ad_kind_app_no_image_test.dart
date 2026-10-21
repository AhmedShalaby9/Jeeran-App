// An app ad has no compound/property to fall back on for a photo. Before this guard, Continue stayed
// enabled with no image attached, and the admin only found out 2–3 steps later, as a 400 from
// /ad-studio/generate ("Add at least one image for the app…") — see CLAUDE.md's "AI ads" section.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_brief_page.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_flow_widgets.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';

import 'ad_studio_support.dart';

class _FakeApi extends AdStudioApi {
  Map<String, dynamic>? briefJson;

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

  testWidgets('an app ad with no image yet: Continue is blocked with a clear reason instead of a dead-end 400 at generate', (t) async {
    t.view.physicalSize = const Size(390 * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final api = _FakeApi();
    await showPage(t, AdBriefPage(api: api, pickImages: () async => const []));
    await settle(t);

    await t.enterText(find.byKey(const Key('ad-summary')), 'Social post about the app, zero commission, new logo attached');
    await t.tap(find.byKey(const Key('ad-kind-app')));
    await settle(t);

    expect(find.byKey(const Key('ad-need-image')), findsOneWidget);
    final btn = t.widget<AdPrimary>(find.byKey(const Key('ad-continue')));
    expect(btn.onPressed, isNull); // disabled — never reaches the server with images: []
    expect(api.briefJson, isNull);
  });
}
