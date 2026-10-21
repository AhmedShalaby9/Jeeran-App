import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_export.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_finish_page.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';

import 'ad_studio_support.dart';

const _fact = {'key': 'from_price', 'label_en': 'From EGP 11.2M', 'label_ar': 'من ١١٫٢ مليون ج.م', 'detail_en': 'Lowest of 16 live units', 'source': 'live inventory', 'numbers': [11.2, 11200000, 16]};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpAdStudioTests);
  tearDown(() {
    AdExporter.renderOverride = null;
    AdExporter.saveOverride = null;
  });

  testWidgets('Your AI ad: edit the words, the edited fields lose the AI mark, and what is downloaded is the edited ad', (t) async {
    t.view.physicalSize = const Size(390 * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final draft = AdDraft.fromJson({
      'id': 7,
      'title': 'City Gate',
      'brief': {'size': 'post', 'width': 1080, 'height': 1350, 'subject': {'en': 'City Gate', 'ar': 'سيتي جيت'}},
      'variations': [],
    });
    final v = AdVariation.fromJson({
      'id': 'v2', 'tone': 'Offer-led', 'head_en': 'From EGP 11.2M', 'sub_en': 'Golf-view family homes', 'cta_en': 'See units',
      'head_ar': '', 'sub_ar': '', 'cta_ar': '', 'image_url': 'https://cdn/a.jpg', 'ai_image': true, 'facts': [_fact],
    });
    final rendered = <AdArtworkData>[];
    final saved = <String>[];
    AdExporter.renderOverride = (ctx, d) async {
      rendered.add(d);
      return Uint8List.fromList([1]);
    };
    AdExporter.saveOverride = (bytes, name) async => saved.add(name);
    await showPage(t, AdFinishPage(draft: draft, variation: v));
    await settle(t);

    expect(find.text('Your AI ad'), findsOneWidget);
    expect(find.text('1080 × 1350 px'), findsOneWidget);
    // an AI ad is a picture: no label to set, nothing to schedule or publish
    expect(find.text('Publish ad'), findsNothing);
    expect(find.text('Label'), findsNothing);
    expect(find.textContaining('Explore'), findsNothing);

    final marks = find.text('Jeeran');
    final before = marks.evaluate().length;
    expect(before, 3); // headline, subline and button were written by the AI
    await t.enterText(find.byKey(const Key('ad-f-sub_en')), 'Golf-view homes for families');
    await settle(t);
    expect(marks.evaluate().length, before - 1);

    await t.tap(find.byKey(const Key('ad-download')));
    await settle(t);
    final d = rendered.single;
    expect((d.width, d.height), (1080, 1350));
    expect(d.head, 'From EGP 11.2M');
    expect(d.sub, 'Golf-view homes for families'); // the edit is in the file
    expect(d.cta, 'See units');
    expect(saved.single, 'jeeran-ai-ad-7-v2-1080x1350');
  });
}
