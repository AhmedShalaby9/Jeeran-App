import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_brief_page.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/dev_picker.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/promo_picker.dart';

import 'ad_studio_support.dart';

const _fromPrice = {'key': 'from_price', 'label_en': 'From EGP 11.2M', 'label_ar': 'من ١١٫٢ مليون ج.م', 'detail_en': 'Lowest of 16 live units', 'source': 'live inventory', 'default_on': true, 'numbers': [11.2, 11200000, 16]};
const _units = {'key': 'units_available', 'label_en': '16 units available', 'label_ar': '١٦ وحدة متاحة', 'detail_en': 'Live count today', 'source': 'live inventory', 'default_on': false, 'numbers': [16]};

Map<String, dynamic> _variation(String id, String tone, String head, String sub, String cta, {List<Map<String, dynamic>> facts = const [], bool ai = true, bool fallback = false}) => {
  'id': id, 'tone': tone, 'head_en': head, 'sub_en': sub, 'cta_en': cta, 'head_ar': '', 'sub_ar': '', 'cta_ar': '',
  'image_url': 'https://x/$id.jpg', 'ai_image': ai, 'facts': facts, 'fallback': fallback,
};

class _FakeApi extends AdStudioApi {
  final calls = <String>[];
  List<String>? approvedSent;
  AdUnderstood? understoodSent;
  AdBrief? briefSent;
  Map<String, dynamic>? briefJson;

  @override
  Future<AdBriefResult> brief(AdBrief b) async {
    calls.add('brief');
    return AdBriefResult.fromJson({
      'understood': {'audience': 'Families', 'angle': 'Ready to move', 'feel': 'Calm, premium', 'must_show': null},
      'facts': [_fromPrice, _units],
      'images': ['https://x/a.jpg'],
      'subject': {'en': 'City Gate', 'ar': 'سيتي جيت'},
      'sponsor': {'id': 24, 'name': 'Qatari Diar'},
      'target': {'type': 'compound', 'id': 644},
    });
  }

  @override
  Future<AdDraft> generate(AdBrief b, {required AdUnderstood understood, required List<String> approved}) async {
    calls.add('generate');
    approvedSent = approved;
    understoodSent = understood;
    briefSent = b;
    briefJson = b.toJson();
    return AdDraft.fromJson({
      'id': 7,
      'title': 'City Gate · Offer-led',
      'brief': {'width': b.pixels.$1, 'height': b.pixels.$2, 'image_mode': b.imageMode, 'sponsor': {'id': 24, 'name': 'Qatari Diar'}, 'target': {'type': 'compound', 'id': 644}, 'subject': {'en': 'City Gate', 'ar': 'سيتي جيت'}},
      'variations': [
        _variation('v1', 'Offer-led', 'Calm family living', 'Golf views at City Gate', 'See units'),
        _variation('v2', 'Premium', 'From EGP 11.2M', 'Golf-view family homes', 'Explore', facts: [_fromPrice]),
        _variation('v3', 'Direct', 'City Gate', 'From EGP 11.2M', 'See units', facts: [_fromPrice], ai: false, fallback: true),
      ],
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpAdStudioTests);

  testWidgets('brief → check → generate → pick → the finish step opens filled in', (t) async {
    t.view.physicalSize = const Size(390 * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final api = _FakeApi();
    await showPage(t, AdBriefPage(
      api: api,
      loadDevelopers: () async => const [DevRef(24, 'ديار القطرية', 'Qatari Diar', compounds: 2, units: 25)],
      loadPromo: (kind, q) async => kind == 'compound'
          ? [const PromoPick('compound', 644, 'City Gate', '16 live units · from EGP 11.2M')]
          : [const PromoPick('unit', 6685, 'Apartment in The Flow', 'EGP 4.3M · 111 m²')],
    ));
    await settle(t);

    // no summary, no Continue
    expect(find.text('Write a summary to continue'), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-continue')));
    await settle(t);
    expect(api.calls, isEmpty);

    await t.enterText(find.byKey(const Key('ad-summary')), 'Ready villas for summer 2027, families, golf view');

    // developer: the card shows its name and what it has
    await t.tap(find.byKey(const Key('ad-dev')));
    await settle(t);
    await t.tap(find.byKey(const Key('dev-24')));
    await settle(t);
    expect(find.text('2 compounds · 25 live units'), findsOneWidget);
    expect(find.textContaining("The AI uses Qatari Diar's live prices and photos."), findsOneWidget);

    // promoting: a compound, then switch to a unit from the card's tabs
    await t.tap(find.byKey(const Key('ad-promo')));
    await settle(t);
    await t.tap(find.byKey(const Key('promo-compound-644')));
    await settle(t);
    expect(find.text('16 live units · from EGP 11.2M'), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-promo-unit')));
    await settle(t);
    await t.tap(find.byKey(const Key('promo-unit-6685')));
    await settle(t);
    expect(find.text('EGP 4.3M · 111 m²'), findsOneWidget);

    await t.tap(find.byKey(const Key('ad-mode-original')));
    await t.tap(find.byKey(const Key('ad-size-story')));
    await t.tap(find.byKey(const Key('ad-tone-Offer-led')));
    await settle(t);
    await t.tap(find.byKey(const Key('ad-continue')));
    await settle(t);
    expect(api.calls, ['brief']);

    // ── check: what the AI understood + facts
    expect(find.text('Families'), findsOneWidget);
    expect(find.text('From EGP 11.2M'), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-u-0')));
    await settle(t);
    await t.enterText(find.byKey(const Key('ad-understood-field')), 'Young families');
    await t.tap(find.byKey(const Key('ad-understood-ok')));
    await settle(t);
    expect(find.text('Young families'), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-fact-units_available')));
    await settle(t);
    await t.tap(find.byKey(const Key('ad-generate')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await settle(t);

    expect(api.approvedSent, ['from_price', 'units_available']);
    expect(api.understoodSent!.audience, 'Young families');
    // everything the brief screen collected reached the server
    final sent = api.briefJson!;
    expect(sent['property_id'], 6685);
    expect(sent['compound_id'], isNull); // switching to a unit replaced the compound
    expect(sent['developer_id'], 24);
    expect(sent['tone'], 'Offer-led');
    expect(sent['image_mode'], 'original');
    expect(sent['size'], 'story');

    // ── results: a swipeable row of three, each with its button, and the facts it really quotes
    expect(find.byKey(const Key('ad-var-0')), findsOneWidget);
    expect(find.byKey(const Key('ad-no-facts-in-ad')), findsOneWidget); // variation 1 quotes no data
    expect(find.text('See units'), findsWidgets);
    await t.drag(find.byType(PageView), const Offset(-260, 0));
    await t.pumpAndSettle(); // the page snaps into place; taps are ignored while it moves
    await t.tap(find.byKey(const Key('ad-var-1')));
    await settle(t);
    expect(find.byKey(const Key('ad-used-from_price')), findsOneWidget);
    expect(find.text('Use variation 2'), findsOneWidget);
    await t.tap(find.byKey(const Key('ad-use')));
    await settle(t);

    // ── your AI ad: filled from variation 2, the AI mark on the fields it wrote
    expect(find.text('Your AI ad'), findsOneWidget);
    expect((t.widget(find.byKey(const Key('ad-f-head_en'))) as TextField).controller!.text, 'From EGP 11.2M');
    expect((t.widget(find.byKey(const Key('ad-f-cta_en'))) as TextField).controller!.text, 'Explore');
    expect(find.text('Download'), findsOneWidget);
  });
}
