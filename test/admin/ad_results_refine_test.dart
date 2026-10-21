import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_results_page.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';

import 'ad_studio_support.dart';

Map<String, dynamic> _v(String id, String head, {String cta = 'See units'}) => {
  'id': id, 'tone': 'Premium', 'head_en': head, 'sub_en': 'Golf views', 'cta_en': cta, 'head_ar': '', 'sub_ar': '', 'cta_ar': '',
  'image_url': 'https://x/$id.jpg', 'ai_image': true, 'facts': [],
};

AdDraft _draft(List<String> heads) => AdDraft.fromJson({
  'id': 7,
  'title': 'City Gate · Premium',
  'brief': {'slot': 'explore_top', 'sponsor': {'id': 24, 'name': 'Qatari Diar'}, 'target': {'type': 'compound', 'id': 644}, 'subject': {'en': 'City Gate', 'ar': 'سيتي جيت'}},
  'variations': [for (var i = 0; i < heads.length; i++) _v('v${i + 1}', heads[i])],
});

class _Api extends AdStudioApi {
  final calls = <String>[];
  bool changed = true;

  @override
  Future<(AdDraft, bool)> refine(int draftId, String variationId, String action) async {
    calls.add('$draftId:$variationId:$action');
    if (!changed) return (_draft(['Calm family living', 'Own a golf-view home', 'City Gate']), false);
    return (_draft(['Family living', 'Own a golf-view home', 'City Gate']), true);
  }

  @override
  Future<AdDraft> regenerate(int draftId) async {
    calls.add('regenerate:$draftId');
    return _draft(['Brand new one', 'Brand new two', 'Brand new three']);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpAdStudioTests);

  testWidgets('refine the picked variation in place, say so when nothing better came, and regenerate all three', (t) async {
    t.view.physicalSize = const Size(390 * 3, 1700 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final api = _Api();
    await showPage(t, AdResultsPage(api: api, draft: _draft(['Calm family living', 'Own a golf-view home', 'City Gate'])));
    await settle(t);

    expect(find.text('Calm family living'), findsOneWidget);
    // "Shorter headline" rewrites the picked variation (the first) and keeps the others
    await t.tap(find.byKey(const Key('ad-refine-shorter')));
    await settle(t);
    expect(api.calls.last, '7:v1:shorter');
    expect(find.text('Family living'), findsOneWidget);
    expect(find.text('Calm family living'), findsNothing);

    // nothing better: the admin is told instead of seeing nothing happen
    api.changed = false;
    await t.tap(find.byKey(const Key('ad-refine-urgent')));
    await settle(t);
    expect(api.calls.last, '7:v1:urgent');
    expect(find.byKey(const Key('ad-note')), findsOneWidget);

    await t.tap(find.byKey(const Key('ad-refine-photo')));
    await settle(t);
    expect(api.calls.last, '7:v1:photo');

    // Regenerate: three new variations, the first selected again
    await t.tap(find.byKey(const Key('ad-regenerate')));
    await settle(t);
    expect(api.calls.last, 'regenerate:7');
    expect(find.text('Brand new one'), findsOneWidget);
    expect(find.text('Calm family living'), findsNothing);
  });
}
