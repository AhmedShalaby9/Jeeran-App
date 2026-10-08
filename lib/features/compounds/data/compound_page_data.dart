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
  const CompoundDeveloperBrief(this.id, this.name, this.logo, this.isVerified);
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
    );
  }

  /// Facilities in the reader's language, falling back to the other list when empty.
  List<String> facilities(bool arabic) {
    final first = arabic ? facilitiesAr : facilitiesEn;
    return first.isNotEmpty ? first : (arabic ? facilitiesEn : facilitiesAr);
  }
}
