import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_page.dart';

import 'ad_studio_support.dart';

AdDraft _ad(int id, String title, {int w = 1200, int h = 825}) => AdDraft.fromJson({
  'id': id,
  'title': title,
  'created_at': '2026-10-14T10:00:00Z',
  'brief': {'width': w, 'height': h},
  'variations': [
    {'id': 'v1', 'image_url': ''},
    {'id': 'v2'},
    {'id': 'v3'},
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpAdStudioTests);

  testWidgets('AI ads: the list shows each one with its size, and an AI ad can be deleted', (t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final discarded = <int>[];
    await showPage(t, AdStudioPage(
      loadDrafts: () async => [_ad(9, 'City Gate · Premium'), _ad(8, 'Mivida · Offer', w: 1080, h: 1920)],
      discardDraft: (id) async => discarded.add(id),
    ));
    await settle(t);

    expect(find.text('AI ads'), findsOneWidget); // the page is called AI ads
    expect(find.text('New AI ad'), findsOneWidget);
    expect(find.text('City Gate · Premium'), findsOneWidget);
    expect(find.textContaining('1200×825'), findsOneWidget);
    expect(find.textContaining('1080×1920'), findsOneWidget);
    // nothing here is published or listed: no status chips, no Explore wording
    expect(find.text('Live'), findsNothing);
    expect(find.textContaining('Explore'), findsNothing);

    await t.tap(find.byKey(const Key('draft-menu-9')));
    await settle(t);
    await t.tap(find.byKey(const Key('draft-discard')));
    await settle(t);
    await t.tap(find.byKey(const Key('ad-delete-confirm')));
    await settle(t);
    expect(discarded, [9]);
    expect(find.text('City Gate · Premium'), findsNothing);
    expect(find.text('Mivida · Offer'), findsOneWidget);
  });
}
