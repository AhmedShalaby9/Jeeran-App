import '../../compounds/data/compound_page_data.dart';

/// What the developer page paints, parsed from `GET /developers/:id` (API v2).

String? _str(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
int? _int(dynamic v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
double? _dbl(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

class DeveloperCompoundRow {
  final int id;
  final Bi name;
  final Bi area;
  final String? image;
  final String? status; // new_launch | offer | selling | resale_only
  final double? minPrice;
  final int unitsCount;

  const DeveloperCompoundRow({
    required this.id,
    required this.name,
    required this.area,
    required this.image,
    required this.status,
    required this.minPrice,
    required this.unitsCount,
  });

  factory DeveloperCompoundRow.fromJson(Map<String, dynamic> j) {
    final area = j['area'];
    return DeveloperCompoundRow(
      id: _int(j['id']) ?? 0,
      name: Bi.of(j, 'name'),
      area: area is Map<String, dynamic>
          ? Bi.of(area, 'name')
          : const Bi('', ''),
      image: _str(j['main_image']),
      status: j['status'] as String?,
      minPrice: _dbl(j['min_price']),
      unitsCount: _int(j['units_count']) ?? 0,
    );
  }
}

class TrustItem {
  final Bi title;
  final Bi detail;
  const TrustItem(this.title, this.detail);
}

class DeveloperPageData {
  final int id;
  final Bi name;
  final Bi desc;
  final String? logo;
  final String? cover;
  final bool isVerified;
  final bool isFollowing;
  final int followersCount;
  final int compoundsCount;
  final int unitsCount;
  final int? deliveredUnits;
  final int? foundedYear;
  final String? stockListing;
  final String? headOffice;
  final List<TrustItem> trustItems; // empty unless the developer is verified
  final List<DeveloperCompoundRow> compounds;

  const DeveloperPageData({
    required this.id,
    required this.name,
    required this.desc,
    required this.logo,
    required this.cover,
    required this.isVerified,
    required this.isFollowing,
    required this.followersCount,
    required this.compoundsCount,
    required this.unitsCount,
    required this.deliveredUnits,
    required this.foundedYear,
    required this.stockListing,
    required this.headOffice,
    required this.trustItems,
    required this.compounds,
  });

  factory DeveloperPageData.fromJson(Map<String, dynamic> j) {
    final stats = j['stats'] is Map<String, dynamic>
        ? j['stats'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final verified = j['is_verified'] == true;
    final compounds =
        (j['compounds'] is List ? j['compounds'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .where((c) => c['is_active'] != false)
            .map(DeveloperCompoundRow.fromJson)
            .toList();

    return DeveloperPageData(
      id: _int(j['id']) ?? 0,
      name: Bi.of(j, 'name'),
      desc: Bi.of(j, 'desc'),
      logo: _str(j['logo']),
      cover: _str(j['cover_image']),
      isVerified: verified,
      isFollowing: j['is_following'] == true,
      followersCount: _int(j['followers_count']) ?? 0,
      compoundsCount: _int(stats['compounds_count']) ?? compounds.length,
      unitsCount: _int(stats['units_count']) ?? 0,
      deliveredUnits: _int(j['delivered_units']),
      foundedYear: _int(j['founded_year']),
      stockListing: _str(j['stock_listing']),
      headOffice: _str(j['address']),
      // the server already hides these for unverified developers; check again here
      trustItems: !verified
          ? const []
          : (j['trust_items'] is List ? j['trust_items'] as List : const [])
                .whereType<Map<String, dynamic>>()
                .map((t) => TrustItem(Bi.of(t, 'title'), Bi.of(t, 'detail')))
                .toList(),
      compounds: compounds,
    );
  }
}
