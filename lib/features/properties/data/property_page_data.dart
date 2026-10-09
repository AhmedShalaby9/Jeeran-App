import '../../compounds/data/compound_page_data.dart';

// What the property page paints, parsed from `GET /properties/:id` (API v2).

String? _s(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
int? _i(dynamic v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
double? _d(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
List<String> _strings(dynamic v) => v is List
    ? v.whereType<String>().where((x) => x.trim().isNotEmpty).toList()
    : const [];

class PropertyCompoundBrief {
  final int id;
  final Bi name;
  final String? image;
  final Bi area;
  final int unitsCount;
  final int phasesCount;
  const PropertyCompoundBrief(
    this.id,
    this.name,
    this.image,
    this.area,
    this.unitsCount,
    this.phasesCount,
  );
}

class PropertyDeveloperBrief {
  final int id;
  final Bi name;
  final String? logo;
  final bool isVerified;
  final int compoundsCount;
  final int unitsCount;
  const PropertyDeveloperBrief(
    this.id,
    this.name,
    this.logo,
    this.isVerified,
    this.compoundsCount,
    this.unitsCount,
  );
}

class PropertyPageData {
  final int id;
  final Bi title;
  final Bi content;
  final double? price;
  final double? pricePerM2;
  final double? size;
  final double? garden;
  final int? beds;
  final int? baths;
  final String propertyType;
  final String status; // for_sale | for_rent | for_rent_furnished
  final String listingType; // primary | resale
  final List<String> images;
  final String? videoUrl;
  final String? floorPlan;
  final bool coverIsAi;
  final bool isFeatured;
  final Bi level;
  final Bi maintenance;
  final String? referenceCode;
  final DateTime? publishedAt;
  final Bi phase;
  final PropertyCompoundBrief? compound;
  final PropertyDeveloperBrief? developer;

  // inherited from the compound when the unit has no value of its own
  final DateTime? deliveryDate;
  final bool? isReady;
  final String? finishing;
  final List<String> paymentOptions;
  final double? downPaymentPercent;
  final int? installmentYears;
  final List<String> amenities;

  final String? agentName;
  final String? agentMobile;
  final String? agentWhatsapp;
  final String? agentPicture;
  final bool sellerVerified;
  final bool isFavorited;

  const PropertyPageData({
    required this.id,
    required this.title,
    required this.content,
    required this.price,
    required this.pricePerM2,
    required this.size,
    required this.garden,
    required this.beds,
    required this.baths,
    required this.propertyType,
    required this.status,
    required this.listingType,
    required this.images,
    required this.videoUrl,
    required this.floorPlan,
    this.coverIsAi = false,
    required this.isFeatured,
    required this.level,
    required this.maintenance,
    required this.referenceCode,
    required this.publishedAt,
    required this.phase,
    required this.compound,
    required this.developer,
    required this.deliveryDate,
    required this.isReady,
    required this.finishing,
    required this.paymentOptions,
    required this.downPaymentPercent,
    required this.installmentYears,
    required this.amenities,
    required this.agentName,
    required this.agentMobile,
    required this.agentWhatsapp,
    required this.agentPicture,
    required this.sellerVerified,
    required this.isFavorited,
  });

  factory PropertyPageData.fromJson(Map<String, dynamic> j) {
    final c = j['compound'] is Map<String, dynamic>
        ? j['compound'] as Map<String, dynamic>
        : null;
    final d = c?['developer'] is Map<String, dynamic>
        ? c!['developer'] as Map<String, dynamic>
        : null;
    final a = c?['area'] is Map<String, dynamic>
        ? c!['area'] as Map<String, dynamic>
        : null;
    final chain = j['chain'] is Map<String, dynamic>
        ? j['chain'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final chainC = chain['compound'] is Map<String, dynamic>
        ? chain['compound'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final chainD = chain['developer'] is Map<String, dynamic>
        ? chain['developer'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final e = j['effective'] is Map<String, dynamic>
        ? j['effective'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final phase = j['phase'] is Map<String, dynamic>
        ? Bi.of(j['phase'] as Map<String, dynamic>, 'name')
        : const Bi('', '');

    return PropertyPageData(
      id: _i(j['id']) ?? 0,
      title: Bi.of(j, 'title'),
      content: Bi.of(j, 'content'),
      price: _d(j['price']),
      pricePerM2: _d(j['price_per_m2']),
      size: _d(j['size']),
      garden: _d(j['garden_size']),
      beds: _i(j['bedrooms']),
      baths: _i(j['bathrooms']),
      propertyType: _s(j['property_type']) ?? '',
      status: _s(j['property_status']) ?? 'for_sale',
      listingType: _s(j['listing_type']) ?? 'primary',
      images: _strings(j['images']),
      videoUrl: _s(j['video_url']),
      floorPlan: _s(j['floor_plan']),
      coverIsAi: j['cover_is_ai'] == true,
      isFeatured: j['is_featured'] == true,
      level: Bi.of(j, 'level'),
      maintenance: Bi.of(j, 'maintenance'),
      referenceCode: _s(j['reference_code']),
      publishedAt: j['published_at'] is String
          ? DateTime.tryParse(j['published_at'] as String)
          : null,
      phase: phase,
      compound: c == null || _i(c['id']) == null
          ? null
          : PropertyCompoundBrief(
              _i(c['id'])!,
              Bi.of(c, 'name'),
              _s(c['main_image']),
              a == null ? const Bi('', '') : Bi.of(a, 'name'),
              _i(chainC['units_count']) ?? 0,
              _i(chainC['phases_count']) ?? 0,
            ),
      developer: d == null || _i(d['id']) == null
          ? null
          : PropertyDeveloperBrief(
              _i(d['id'])!,
              Bi.of(d, 'name'),
              _s(d['logo']),
              d['is_verified'] == true,
              _i(chainD['compounds_count']) ?? 0,
              _i(chainD['units_count']) ?? 0,
            ),
      deliveryDate: e['delivery_date'] is String
          ? DateTime.tryParse(e['delivery_date'] as String)
          : null,
      isReady: e['is_ready'] is bool ? e['is_ready'] as bool : null,
      finishing: _s(e['finishing']),
      paymentOptions: _strings(e['payment_options']),
      downPaymentPercent: _d(e['down_payment_percent']),
      installmentYears: _i(e['installment_years']),
      amenities: _strings(e['amenities']),
      agentName: _s(j['agent_name']),
      agentMobile: _s(j['agent_mobile']),
      agentWhatsapp: _s(j['agent_whatsapp']),
      agentPicture: _s(j['agent_picture']),
      sellerVerified: j['seller_verified'] == true,
      isFavorited: j['is_favorited'] == true,
    );
  }

  /// Photos first, then the floor plan, so a buyer swiping sees the plan last.
  List<String> get gallery => [...images, if (floorPlan != null) floorPlan!];
}
