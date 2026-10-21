import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/admin/ad_studio/ad_studio_api.dart';

void main() {
  test('a brief result reads the understood lines, the facts, the sponsor and the target', () {
    final r = AdBriefResult.fromJson({
      'understood': {'audience': 'Families', 'angle': '  ', 'feel': 'Calm', 'must_show': null},
      'facts': [
        {'key': 'from_price', 'label_en': 'From EGP 9.8M', 'label_ar': 'من ٩٫٨ مليون', 'detail_en': 'Lowest of 142 live units', 'source': 'live inventory', 'default_on': true, 'numbers': [9.8, 9800000, 142]},
      ],
      'images': ['https://x/1.jpg', 7],
      'subject': {'en': 'Marassi', 'ar': 'مراسي'},
      'sponsor': {'id': 3, 'name': 'Emaar Misr'},
      'target': {'type': 'compound', 'id': 5},
    });
    expect(r.understood.audience, 'Families');
    expect(r.understood.angle, isNull); // blank means not said
    expect(r.facts.single.defaultOn, isTrue);
    expect(r.facts.single.numbers, [9.8, 9800000, 142]);
    expect(r.facts.single.label(true), 'من ٩٫٨ مليون');
    expect(r.images, ['https://x/1.jpg']); // junk entries are dropped
    expect(r.sponsorName, 'Emaar Misr');
    expect(r.targetType, 'compound');
    expect(r.targetId, 5);
  });

  test('a draft keeps what the composer needs: the slot, sponsor, target and the facts each variation quotes', () {
    final d = AdDraft.fromJson({
      'id': 4,
      'title': 'Marassi · Premium',
      'brief': {'slot': 'explore_feed', 'sponsor': {'id': 3, 'name': 'Emaar Misr'}, 'target': {'type': 'compound', 'id': 5}, 'subject': {'en': 'Marassi', 'ar': 'مراسي'}},
      'variations': [
        {'id': 'v1', 'tone': 'Premium', 'head_en': 'Lagoon living', 'head_ar': 'مراسي', 'facts': [{'key': 'from_price', 'label_en': 'From EGP 9.8M', 'numbers': [9.8]}], 'fallback': true},
      ],
    });
    expect(d.slot, 'explore_feed');
    expect(d.developerId, 3);
    expect(d.subjectAr, 'مراسي');
    expect(d.variations.single.fallback, isTrue);
    expect(d.variations.single.head(true), 'مراسي');
    expect(d.variations.single.facts.single.toJson()['numbers'], [9.8]);
  });
}
