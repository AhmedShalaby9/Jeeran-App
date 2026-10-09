import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/features/explore/data/models/explore_data.dart';

/// Shape of `GET /api/home` (captured from the backend on the dev DB).
/// Exposed so the layout test renders the same payload.
const homeFixture = _home;

const _home = {
  'banners': {
    'explore_top': [
      {
        'id': 4,
        'slot': 'explore_top',
        'kind': 'sponsored',
        'media_type': 'video',
        'image_url': 'https://x/p.jpg',
        'video_url': 'https://x/v.mp4',
        'video_duration': 18,
        'caption_en': 'Marina Rise now selling',
        'caption_ar': null,
        'sub_en': null,
        'sub_ar': null,
        'target_type': 'project',
        'target_id': 1,
        'sponsor_name': 'Emaar Misr',
        'link': null,
        'phone': null,
      },
      {
        'id': 7,
        'slot': 'explore_top',
        'kind': 'internal',
        'media_type': 'image',
        'image_url': '',
        'target_type': 'none',
      },
    ],
    'explore_feed': {
      'id': 5,
      'slot': 'explore_feed',
      'kind': 'internal',
      'media_type': 'image',
      'image_url': 'https://x/f.jpg',
      'caption_en': 'Inside Hacienda Bay',
    },
  },
  'facets': {
    'total': 3,
    'types': {'chalet': 1, 'villa': 1, 'apartment': 1},
    'statuses': {'for_sale': 2, 'for_rent': 1},
  },
  'launches': [
    {
      'id': 1,
      'name_ar': 'مراسي',
      'name_en': 'Marassi',
      'gallery': [],
      'features': [],
      'is_active': true,
      'is_new_launch': true,
      'state': 'north_coast',
      'area_en': null,
      'min_price': 8950000,
      'units_count': 3,
      'developer': {
        'id': 1,
        'name_ar': 'إعمار',
        'name_en': 'Emaar Misr',
        'logo': null,
      },
    },
  ],
  'top_compounds': [
    {
      'id': 1,
      'name_ar': 'مراسي',
      'name_en': 'Marassi',
      'gallery': [],
      'features': [],
      'is_active': true,
      'rank': 1,
      'views': 42,
      'min_price': 9750000,
      'units_count': 3,
      'area': {
        'name_ar': 'الساحل الشمالي',
        'name_en': 'North Coast',
        'state': 'north_coast',
      },
      'developer': {
        'id': 1,
        'name_ar': 'إعمار',
        'name_en': 'Emaar Misr',
        'logo': null,
      },
    },
    {
      'id': 2,
      'name_ar': 'هاسيندا',
      'name_en': 'Hacienda Bay',
      'gallery': [],
      'features': [],
      'is_active': true,
      'rank': 2,
      'views': 9,
      'min_price': 11200000,
      'units_count': 2,
    },
  ],
  'featured': [
    {
      'id': 9,
      'title_ar': 'شالية',
      'title_en': 'Chalet',
      'images': ['https://x/a.jpg'],
      'price': '12400000.00',
      'is_featured': true,
      'is_favorited': true,
      'project': {
        'id': 1,
        'name_ar': 'مراسي',
        'name_en': 'Marassi',
        'gallery': [],
        'features': [],
        'is_active': true,
        'developer': {'id': 1, 'name_ar': 'إعمار', 'name_en': 'Emaar Misr'},
      },
    },
  ],
  'news': [
    {
      'id': 4,
      'title': 'News one',
      'content': '<p>Body</p>',
      'excerpt': 'Body',
      'media': [],
      'is_active': true,
      'published_at': '2026-10-06T16:16:28.000Z',
      'published_by': null,
    },
  ],
  'seller_request': {
    'id': 4,
    'status': 'rejected',
    'rejection_reason': 'Add a valid ID',
    'created_at': '2026-10-04T10:00:00.000Z',
  },
  'unread_count': 2,
  'saved_count': 5,
  'you_attention': true,
};

void main() {
  group('ExploreData.fromJson', () {
    final d = ExploreData.fromJson(Map<String, dynamic>.from(_home));

    test('banners: placed by slot, empty-image creatives dropped', () {
      expect(d.topBanners.map((b) => b.id), [4]);
      final b = d.topBanners.single;
      expect(b.isVideo, isTrue);
      expect(b.isSponsored, isTrue);
      expect(b.durationLabel, '0:18');
      expect(
        b.caption(true),
        'Marina Rise now selling',
      ); // falls back when no Arabic caption
      expect(b.targetType, 'project');
      expect(d.feedBanner?.id, 5);
    });

    test('facets feed the quick grid', () {
      expect(d.typeCounts['chalet'], 1);
      expect(d.statusCounts['for_rent'], 1);
    });

    test('top compounds arrive ranked, with price and units', () {
      final d = ExploreData.fromJson(Map<String, dynamic>.from(_home));
      expect(d.topCompounds.map((c) => c.id), [1, 2]);
      expect(d.topCompounds.first.minPrice, 9750000);
      expect(d.topCompounds.first.unitsCount, 3);
      expect(d.topCompounds.first.developer!.nameEn, 'Emaar Misr');
    });

    test('launch carries developer + location + starting price', () {
      final p = d.launches.single;
      expect(p.isNewLaunch, isTrue);
      expect(p.developer?.name, 'Emaar Misr');
      expect(p.areaLabel, 'North Coast');
      expect(p.minPrice, 8950000);
      expect(p.unitsCount, 3);
    });

    test('featured property keeps its Project → Developer link', () {
      final p = d.featured.single;
      expect(p.isFavorited, isTrue);
      expect(p.project?.developer?.name, 'Emaar Misr');
    });

    test('news, seller request and tab badges', () {
      expect(d.news.single.title, 'News one');
      expect(d.sellerRequest?.isRejected, isTrue);
      expect(d.sellerRequest?.rejectionReason, 'Add a valid ID');
      expect(d.unreadCount, 2);
      expect(d.savedCount, 5);
      expect(d.youAttention, isTrue);
    });
  });

  test('a guest response parses with safe defaults', () {
    final d = ExploreData.fromJson({
      'banners': {'explore_top': [], 'explore_feed': null},
      'facets': {'total': 0, 'types': {}, 'statuses': {}},
      'launches': [],
      'featured': [],
      'news': [],
      'seller_request': null,
      'unread_count': 0,
      'saved_count': 0,
      'you_attention': false,
    });
    expect(d.topBanners, isEmpty);
    expect(d.feedBanner, isNull);
    expect(d.sellerRequest, isNull);
    expect(d.topCompounds, isEmpty); // the section hides itself
    expect(d.youAttention, isFalse);
  });
}
