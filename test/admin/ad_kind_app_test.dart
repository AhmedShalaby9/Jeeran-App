// "The app" vs "A place": the first-step toggle that decides whether the ad is tied to a compound/
// developer/unit or is a general ad for the Jeeran app itself. An app ad has no compound to fall back
// on for a photo, so it must block Continue until a real image is attached (instead of silently
// reaching the generate step with images: [] and failing there — see CLAUDE.md's "AI ads" section).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_brief_page.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/dev_picker.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/promo_picker.dart';

import 'ad_studio_support.dart';

class _FakeApi extends AdStudioApi {
  AdBrief? briefSent;
  Map<String, dynamic>? briefJson;
  final List<String> scoreCallKinds = []; // the brief.kind sent on each scoreImages call, in order

  @override
  Future<String> upload(String path) async => 'https://x/logo.png';

  @override
  Future<List<AdImageScore>> scoreImages(List<String> urls, {required AdBrief brief}) async {
    scoreCallKinds.add(brief.kind);
    // a logo: off-brief under "place" rules, fine under "app" rules — matches the real backend's behaviour
    final status = brief.kind == 'app' ? 'ok' : 'warn';
    final label = brief.kind == 'app' ? 'good' : 'off_brief';
    return [for (final u in urls) AdImageScore(url: u, status: status, label: label)];
  }

  @override
  Future<AdBriefResult> brief(AdBrief b) async {
    briefSent = b;
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

  testWidgets('picking "The app" hides developer/promoting, clears any selection, blocks Continue until an image is attached, and sends kind: app', (t) async {
    t.view.physicalSize = const Size(390 * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final api = _FakeApi();
    await showPage(t, AdBriefPage(
      api: api,
      pickImages: () async => ['/tmp/logo.png'],
      loadDevelopers: () async => const [DevRef(24, 'ديار القطرية', 'Qatari Diar', compounds: 2, units: 25)],
      loadPromo: (kind, q) async => kind == 'compound' ? [const PromoPick('compound', 644, 'City Gate', '16 live units · from EGP 11.2M')] : const [],
    ));
    await settle(t);

    await t.enterText(find.byKey(const Key('ad-summary')), 'Get the Jeeran app — browse new launches anywhere in Egypt');

    // link a developer and a compound first, as a normal "place" ad would
    await t.tap(find.byKey(const Key('ad-dev')));
    await settle(t);
    await t.tap(find.byKey(const Key('dev-24')));
    await settle(t);
    await t.tap(find.byKey(const Key('ad-promo')));
    await settle(t);
    await t.tap(find.byKey(const Key('promo-compound-644')));
    await settle(t);
    expect(find.byKey(const Key('ad-dev')), findsOneWidget);
    expect(find.byKey(const Key('ad-promo')), findsOneWidget);

    // upload the logo while still in "place" mode: scored off-brief, so it's excluded
    await t.tap(find.byKey(const Key('ad-add-images')));
    await settle(t);
    expect(api.scoreCallKinds, ['inventory']);

    // switch to "The app": sections disappear, AND the stale off-brief score is thrown out and rechecked under app rules
    await t.tap(find.byKey(const Key('ad-kind-app')));
    await settle(t);
    expect(find.byKey(const Key('ad-dev')), findsNothing);
    expect(find.byKey(const Key('ad-promo')), findsNothing);
    expect(api.scoreCallKinds, ['inventory', 'app']); // rescored under the new kind
    expect(find.byKey(const Key('ad-need-image')), findsNothing); // the logo now scores fine, so Continue isn't blocked

    // continue: the brief the server receives is clean of any compound/developer/unit, and carries the image
    await t.tap(find.byKey(const Key('ad-continue')));
    await settle(t);
    expect(api.briefJson, isNotNull);
    expect(api.briefJson!['kind'], 'app');
    expect(api.briefJson!['developer_id'], isNull);
    expect(api.briefJson!['compound_id'], isNull);
    expect(api.briefJson!['property_id'], isNull);
    expect(api.briefSent!.images, ['https://x/logo.png']);
  });
}
