import 'package:equatable/equatable.dart';

import '../../../news/data/models/news_model.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../properties/data/models/property_model.dart';

/// A banner as the backend stores it: media + caption + tap target, placed by slot.
class ExploreBanner extends Equatable {
  final int id;
  final String slot; // explore_top | explore_feed
  final String kind; // internal | sponsored
  final String mediaType; // image | video
  final String imageUrl; // also the poster for video banners
  final String? videoUrl;
  final int? videoDuration; // seconds
  final String captionEn;
  final String captionAr;
  final String subEn;
  final String subAr;
  final String targetType;
  final int? targetId;
  final String? link;
  final String? phone;
  final String? sponsorName;

  const ExploreBanner({
    required this.id,
    required this.slot,
    required this.kind,
    required this.mediaType,
    required this.imageUrl,
    this.videoUrl,
    this.videoDuration,
    this.captionEn = '',
    this.captionAr = '',
    this.subEn = '',
    this.subAr = '',
    this.targetType = 'none',
    this.targetId,
    this.link,
    this.phone,
    this.sponsorName,
  });

  bool get isVideo => mediaType == 'video';
  bool get isSponsored => kind == 'sponsored';

  String caption(bool arabic) => _pick(arabic, captionAr, captionEn);
  String sub(bool arabic) => _pick(arabic, subAr, subEn);

  static String _pick(bool arabic, String ar, String en) =>
      arabic ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);

  /// "0:18" — null when unknown.
  String? get durationLabel {
    final s = videoDuration;
    if (s == null || s <= 0) return null;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  factory ExploreBanner.fromJson(Map<String, dynamic> j) => ExploreBanner(
    id: j['id'] as int,
    slot: j['slot'] as String? ?? 'explore_top',
    kind: j['kind'] as String? ?? 'internal',
    mediaType: j['media_type'] as String? ?? 'image',
    imageUrl: j['image_url'] as String? ?? '',
    videoUrl: j['video_url'] as String?,
    videoDuration: (j['video_duration'] as num?)?.toInt(),
    captionEn: j['caption_en'] as String? ?? '',
    captionAr: j['caption_ar'] as String? ?? '',
    subEn: j['sub_en'] as String? ?? '',
    subAr: j['sub_ar'] as String? ?? '',
    targetType: j['target_type'] as String? ?? 'none',
    targetId: (j['target_id'] as num?)?.toInt(),
    link: j['link'] as String?,
    phone: j['phone'] as String?,
    sponsorName: j['sponsor_name'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    slot,
    kind,
    mediaType,
    imageUrl,
    videoUrl,
    targetType,
    targetId,
  ];
}

/// Latest seller request of the signed-in user (null if they never applied).
class SellerRequestStatus extends Equatable {
  final String status; // pending | approved | rejected
  final String? rejectionReason;
  final DateTime? createdAt;

  const SellerRequestStatus({
    required this.status,
    this.rejectionReason,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  factory SellerRequestStatus.fromJson(Map<String, dynamic> j) =>
      SellerRequestStatus(
        status: j['status'] as String? ?? 'pending',
        rejectionReason: j['rejection_reason'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [status, rejectionReason, createdAt];
}

/// Everything the Explore screen paints, from `GET /home`.
class ExploreData extends Equatable {
  final List<ExploreBanner> topBanners;
  final ExploreBanner? feedBanner;
  final Map<String, int> typeCounts; // property_type -> listings
  final Map<String, int> statusCounts; // property_status -> listings
  final List<ProjectModel> launches;
  final List<PropertyModel> featured;
  final List<NewsModel> news;
  final SellerRequestStatus? sellerRequest;
  final int unreadCount;
  final int savedCount;
  final bool youAttention;

  const ExploreData({
    this.topBanners = const [],
    this.feedBanner,
    this.typeCounts = const {},
    this.statusCounts = const {},
    this.launches = const [],
    this.featured = const [],
    this.news = const [],
    this.sellerRequest,
    this.unreadCount = 0,
    this.savedCount = 0,
    this.youAttention = false,
  });

  static Map<String, int> _counts(dynamic raw) => raw is Map
      ? {for (final e in raw.entries) e.key as String: (e.value as num).toInt()}
      : <String, int>{};

  static List<T> _list<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) parse,
  ) => raw is List
      ? raw.whereType<Map<String, dynamic>>().map(parse).toList()
      : <T>[];

  factory ExploreData.fromJson(Map<String, dynamic> j) {
    final banners = j['banners'] as Map<String, dynamic>? ?? const {};
    final facets = j['facets'] as Map<String, dynamic>? ?? const {};
    final feed = banners['explore_feed'];
    final seller = j['seller_request'];

    return ExploreData(
      topBanners: _list(
        banners['explore_top'],
        ExploreBanner.fromJson,
      ).where((b) => b.imageUrl.isNotEmpty).toList(),
      feedBanner:
          feed is Map<String, dynamic> &&
              (feed['image_url'] as String? ?? '').isNotEmpty
          ? ExploreBanner.fromJson(feed)
          : null,
      typeCounts: _counts(facets['types']),
      statusCounts: _counts(facets['statuses']),
      launches: _list(j['launches'], ProjectModel.fromJson),
      featured: _list(j['featured'], PropertyModel.fromJson),
      news: _list(j['news'], NewsModel.fromJson),
      sellerRequest: seller is Map<String, dynamic>
          ? SellerRequestStatus.fromJson(seller)
          : null,
      unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      savedCount: (j['saved_count'] as num?)?.toInt() ?? 0,
      youAttention: j['you_attention'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    topBanners,
    feedBanner,
    typeCounts,
    statusCounts,
    launches,
    featured,
    news,
    sellerRequest,
    unreadCount,
    savedCount,
    youAttention,
  ];
}
