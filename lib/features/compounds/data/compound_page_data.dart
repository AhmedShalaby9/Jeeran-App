// What the compound page paints, parsed from `GET /compounds/:id` (API v2).

String _s(dynamic v) => v is String ? v : '';
int? _i(dynamic v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
double? _d(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
List<String> _strings(dynamic v) => v is List
    ? v.whereType<String>().where((x) => x.trim().isNotEmpty).toList()
    : const [];

/// A bilingual pair — `pick` returns the reader's language, falling back to the other.
/// GeoJSON Polygon / MultiPolygon → the outer rings as [lng, lat] points.
List<List<List<double>>> _rings(dynamic g) {
  if (g is! Map) return const [];
  final c = g['coordinates'];
  if (c is! List) return const [];
  List<List<double>> ring(dynamic r) => [
    for (final p in (r is List ? r : const []))
      if (p is List && p.length >= 2 && p[0] is num && p[1] is num) [(p[0] as num).toDouble(), (p[1] as num).toDouble()],
  ];
  final polys = g['type'] == 'MultiPolygon' ? c : [c];
  return [
    for (final poly in polys)
      if (poly is List && poly.isNotEmpty) ring(poly.first),
  ].where((r) => r.length >= 3).toList();
}

List<double>? _bounds(dynamic v) {
  if (v is! List || v.length != 4 || v.any((x) => x is! num)) return null;
  return [for (final x in v) (x as num).toDouble()];
}

class Bi {
  final String ar;
  final String en;
  const Bi(this.ar, this.en);

  factory Bi.of(Map<String, dynamic> j, String key) =>
      Bi(_s(j['${key}_ar']), _s(j['${key}_en']));

  String pick(bool arabic) =>
      arabic ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
  bool get isEmpty => ar.isEmpty && en.isEmpty;
}

/// derived on the server: selling_now | resale_only | sold_out | coming_soon
class CompoundPhase {
  final int id;
  final Bi name;
  final Bi delivery;
  final int available;
  final double? minPrice;
  final String status;

  const CompoundPhase({
    required this.id,
    required this.name,
    required this.delivery,
    required this.available,
    required this.minPrice,
    required this.status,
  });

  factory CompoundPhase.fromJson(Map<String, dynamic> j) => CompoundPhase(
    id: _i(j['id']) ?? 0,
    name: Bi.of(j, 'name'),
    delivery: Bi.of(j, 'delivery_label'),
    available: _i(j['available_count']) ?? 0,
    minPrice: _d(j['min_price']),
    status: _s(j['status']),
  );
}

class CompoundFact {
  final Bi label;
  final Bi value;
  const CompoundFact(this.label, this.value);

  factory CompoundFact.fromJson(Map<String, dynamic> j) =>
      CompoundFact(Bi.of(j, 'label'), Bi.of(j, 'value'));
}

class CompoundPromotion {
  final String type; // launch | offer
  final Bi title;
  const CompoundPromotion(this.type, this.title);

  factory CompoundPromotion.fromJson(Map<String, dynamic> j) =>
      CompoundPromotion(_s(j['type']), Bi.of(j, 'title'));
}

class CompoundUpdate {
  final String title;
  final bool isFresh;
  const CompoundUpdate(this.title, this.isFresh);
}

class CompoundDeveloperBrief {
  final int id;
  final Bi name;
  final String? logo;
  final bool isVerified;
  final bool
  isTop; // the source's "top developer" mark; not the same as Jeeran's verified tick
  final int compoundsCount;
  final int unitsCount;
  const CompoundDeveloperBrief(
    this.id,
    this.name,
    this.logo,
    this.isVerified, {
    this.isTop = false,
    this.compoundsCount = 0,
    this.unitsCount = 0,
  });
}

/// A question and its answer, from the compound's FAQ list.
class CompoundFaq {
  final Bi question;
  final Bi answer;
  const CompoundFaq(this.question, this.answer);

  factory CompoundFaq.fromJson(Map<String, dynamic> j) =>
      CompoundFaq(Bi.of(j, 'question'), Bi.of(j, 'answer'));
}

class CompoundPageData {
  final int id;
  final Bi name;
  final Bi desc;
  final List<String>
  images; // main image first, then the gallery, no duplicates
  final CompoundDeveloperBrief? developer;
  final Bi area;
  final CompoundPromotion? promotion;
  final String? status; // new_launch | offer | selling | resale_only
  final double? minPrice;
  final int unitsCount;
  final int followersCount;
  final bool isFollowing;
  final bool alertsOn; // following and not muted
  final List<String>? alertEvents; // which kinds it sends; null = all
  final CompoundUpdate? latestUpdate;
  final List<CompoundPhase> phases;
  final List<String> unitTypes;
  final double? sizeMin;
  final double? sizeMax;
  final int? deliveredSince;
  final String? deliveryDate; // yyyy-mm-dd
  final String? finishing;
  final List<String> paymentOptions;
  final double? downPaymentPercent;
  final int? installmentYears;
  final List<String> facilitiesAr;
  final List<String> facilitiesEn;
  final List<CompoundFact> facts;
  final int primaryCount;
  final int resaleCount;
  final List<CompoundFaq> faqs;
  final String?
  masterPlan; // an image of the compound's master plan, when one is published
  final double? latitude;
  final double? longitude;

  /// The compound's outline: rings of [lng, lat] from the GeoJSON polygon (empty when it has none).
  final List<List<List<double>>> boundary;

  /// The georeferenced plan drawn on the map, with where it sits: [west, south, east, north].
  final String? planUrl;
  final List<double>? planBounds;

  /// The map card shows when the compound has a pin.
  bool get hasPin => latitude != null && longitude != null;

  const CompoundPageData({
    required this.id,
    required this.name,
    required this.desc,
    required this.images,
    required this.developer,
    required this.area,
    required this.promotion,
    required this.status,
    required this.minPrice,
    required this.unitsCount,
    required this.followersCount,
    required this.isFollowing,
    this.alertsOn = false,
    this.alertEvents,
    required this.latestUpdate,
    required this.phases,
    required this.unitTypes,
    required this.sizeMin,
    required this.sizeMax,
    required this.deliveredSince,
    required this.deliveryDate,
    required this.finishing,
    required this.paymentOptions,
    required this.downPaymentPercent,
    required this.installmentYears,
    required this.facilitiesAr,
    required this.facilitiesEn,
    required this.facts,
    this.primaryCount = 0,
    this.resaleCount = 0,
    this.faqs = const [],
    this.masterPlan,
    this.latitude,
    this.longitude,
    this.boundary = const [],
    this.planUrl,
    this.planBounds,
  });

  factory CompoundPageData.fromJson(Map<String, dynamic> j) {
    final main = j['main_image'] is String ? j['main_image'] as String : null;
    final images = <String>{
      if (main != null && main.isNotEmpty) main,
      ..._strings(j['gallery']),
    }.toList();

    final dev = j['developer'];
    final area = j['area'];
    final update = j['latest_update'];
    final promo = j['promotion'];

    return CompoundPageData(
      id: _i(j['id']) ?? 0,
      name: Bi.of(j, 'name'),
      desc: Bi.of(j, 'desc'),
      images: images,
      developer: dev is Map<String, dynamic> && _i(dev['id']) != null
          ? CompoundDeveloperBrief(
              _i(dev['id'])!,
              Bi.of(dev, 'name'),
              dev['logo'] as String?,
              dev['is_verified'] == true,
              isTop: dev['is_top'] == true,
              compoundsCount: _i(dev['compounds_count']) ?? 0,
              unitsCount: _i(dev['units_count']) ?? 0,
            )
          : null,
      area: area is Map<String, dynamic>
          ? Bi.of(area, 'name')
          : const Bi('', ''),
      promotion: promo is Map<String, dynamic>
          ? CompoundPromotion.fromJson(promo)
          : null,
      status: j['status'] as String?,
      minPrice: _d(j['min_price']),
      unitsCount: _i(j['units_count']) ?? 0,
      followersCount: _i(j['followers_count']) ?? 0,
      isFollowing: j['is_following'] == true,
      alertsOn: j['is_following'] == true && j['alerts_enabled'] != false,
      alertEvents: j['alert_events'] is List
          ? (j['alert_events'] as List).whereType<String>().toList()
          : null,
      latestUpdate:
          update is Map<String, dynamic> && _s(update['title']).isNotEmpty
          ? CompoundUpdate(_s(update['title']), update['is_fresh'] == true)
          : null,
      phases: (j['phases'] is List ? j['phases'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map(CompoundPhase.fromJson)
          .toList(),
      unitTypes: _strings(j['unit_types']),
      sizeMin: _d(j['size_min']),
      sizeMax: _d(j['size_max']),
      deliveredSince: _i(j['delivered_since']),
      deliveryDate: j['delivery_date'] as String?,
      finishing: j['finishing'] as String?,
      paymentOptions: _strings(j['payment_options']),
      downPaymentPercent: _d(j['down_payment_percent']),
      installmentYears: _i(j['installment_years']),
      facilitiesAr: _strings(j['facilities_ar']),
      facilitiesEn: _strings(j['facilities_en']),
      facts: (j['facts'] is List ? j['facts'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map(CompoundFact.fromJson)
          .toList(),
      primaryCount: _i(j['primary_count']) ?? 0,
      resaleCount: _i(j['resale_count']) ?? 0,
      faqs: (j['faqs'] is List ? j['faqs'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map(CompoundFaq.fromJson)
          .where((f) => !f.question.isEmpty && !f.answer.isEmpty)
          .toList(),
      masterPlan: _s(j['master_plan']).trim().isEmpty
          ? null
          : _s(j['master_plan']).trim(),
      latitude: _d(j['latitude']),
      longitude: _d(j['longitude']),
      boundary: _rings(j['boundary']),
      planUrl: _s(j['plan_overlay_url']).trim().isEmpty ? null : _s(j['plan_overlay_url']).trim(),
      planBounds: _bounds(j['plan_bounds']),
    );
  }

  /// Facilities in the reader's language, falling back to the other list when empty.
  List<String> facilities(bool arabic) {
    final first = arabic ? facilitiesAr : facilitiesEn;
    return first.isNotEmpty ? first : (arabic ? facilitiesEn : facilitiesAr);
  }
}
