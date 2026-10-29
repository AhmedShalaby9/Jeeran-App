import '../../../core/network/api_client.dart';
import 'search_filters.dart';

String? _s(dynamic v) => v is String && v.isNotEmpty ? v : null;

/// An image URL, or null when the field is empty or only spaces.
String? _url(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
int _i(dynamic v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0);

class SearchPage20 {
  final List<Map<String, dynamic>> items;
  final int total;
  final int pages;
  const SearchPage20(this.items, this.total, this.pages);
}

/// One suggestion from `/properties/relax`.
class RelaxSuggestion {
  final String kind; // raise_max_price | lower_min_price | drop_filter
  final int count;
  final int? price; // for the two price kinds
  final String? filter; // for drop_filter
  const RelaxSuggestion(this.kind, this.count, {this.price, this.filter});

  factory RelaxSuggestion.fromJson(Map<String, dynamic> j) => RelaxSuggestion(
    j['kind'] as String? ?? '',
    _i(j['count']),
    price: j['max_price'] != null
        ? _i(j['max_price'])
        : (j['min_price'] != null ? _i(j['min_price']) : null),
    filter: _s(j['filter']),
  );

  SearchFilters applyTo(SearchFilters f) => switch (kind) {
    'raise_max_price' => f.copyWith(maxPrice: price),
    'lower_min_price' => f.copyWith(minPrice: price),
    'drop_filter' when filter != null => f.without(filter!),
    _ => f,
  };
}

class DeveloperSummary {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? logo;
  final bool isVerified;
  final int compounds;
  final int units;

  /// Optional cover photo; without one the card keeps its plain look.
  final String? cover;
  const DeveloperSummary(
    this.id,
    this.nameAr,
    this.nameEn,
    this.logo,
    this.isVerified,
    this.compounds,
    this.units, {
    this.cover,
  });

  factory DeveloperSummary.fromJson(Map<String, dynamic> j) => DeveloperSummary(
    _i(j['id']),
    j['name_ar'] as String? ?? '',
    j['name_en'] as String? ?? '',
    _url(j['logo']),
    j['is_verified'] == true,
    _i(j['compounds_count']),
    _i(j['units_count']),
    cover: _url(j['cover_image']),
  );

  String name(bool ar) => ar
      ? (nameAr.isNotEmpty ? nameAr : nameEn)
      : (nameEn.isNotEmpty ? nameEn : nameAr);

  /// Initials for the avatar: up to three words, or the first two letters of one.
  String get short {
    final words = (nameEn.isNotEmpty ? nameEn : nameAr)
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return words.take(3).map((w) => w[0]).join().toUpperCase();
  }
}

class AreaItem {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? image;
  final int listings;
  const AreaItem(this.id, this.nameAr, this.nameEn, this.image, this.listings);

  factory AreaItem.fromJson(Map<String, dynamic> j) => AreaItem(
    _i(j['id']),
    j['name_ar'] as String? ?? '',
    j['name_en'] as String? ?? '',
    _s(j['image']),
    _i(j['listing_count']),
  );

  String name(bool ar) => ar
      ? (nameAr.isNotEmpty ? nameAr : nameEn)
      : (nameEn.isNotEmpty ? nameEn : nameAr);
}

/// A live launch or offer (`/promotions`).
class PromotionItem {
  final int id;
  final String type; // launch | offer
  final String titleAr;
  final String titleEn;
  final String subAr;
  final String subEn;
  final String? image;
  final bool hasVideo;
  final int? videoSeconds;
  final int compoundId;
  final String compoundNameAr;
  final String compoundNameEn;
  final String developerNameAr;
  final String developerNameEn;
  final double? minPrice;
  final DateTime? endsAt;

  /// Primary units this launch/offer is about; 0 = it points at the whole compound.
  final int propertiesCount;

  const PromotionItem({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.subAr,
    required this.subEn,
    required this.image,
    required this.hasVideo,
    required this.videoSeconds,
    required this.compoundId,
    required this.compoundNameAr,
    required this.compoundNameEn,
    required this.developerNameAr,
    required this.developerNameEn,
    required this.minPrice,
    required this.endsAt,
    this.propertiesCount = 0,
  });

  factory PromotionItem.fromJson(Map<String, dynamic> j) {
    final c = j['compound'] is Map<String, dynamic>
        ? j['compound'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final d = c['developer'] is Map<String, dynamic>
        ? c['developer'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return PromotionItem(
      id: _i(j['id']),
      type: j['type'] as String? ?? 'launch',
      titleAr: j['title_ar'] as String? ?? '',
      titleEn: j['title_en'] as String? ?? '',
      subAr: j['sub_ar'] as String? ?? '',
      subEn: j['sub_en'] as String? ?? '',
      image: _s(j['image']),
      hasVideo: _s(j['video_url']) != null,
      videoSeconds: j['video_duration'] is num
          ? (j['video_duration'] as num).toInt()
          : null,
      compoundId: _i(j['compound_id'] ?? c['id']),
      compoundNameAr: c['name_ar'] as String? ?? '',
      compoundNameEn: c['name_en'] as String? ?? '',
      developerNameAr: d['name_ar'] as String? ?? '',
      developerNameEn: d['name_en'] as String? ?? '',
      // a launch with its own units shows their starting price, not the whole compound's
      minPrice:
          (j['properties_count'] is num &&
              (j['properties_count'] as num) > 0 &&
              j['properties_min_price'] is num)
          ? (j['properties_min_price'] as num).toDouble()
          : (c['min_price'] is num ? (c['min_price'] as num).toDouble() : null),
      endsAt: j['ends_at'] is String
          ? DateTime.tryParse(j['ends_at'] as String)
          : null,
      propertiesCount: (j['properties_count'] as num?)?.toInt() ?? 0,
    );
  }

  String title(bool ar) => ar
      ? (titleAr.isNotEmpty ? titleAr : titleEn)
      : (titleEn.isNotEmpty ? titleEn : titleAr);
  String sub(bool ar) => ar
      ? (subAr.isNotEmpty ? subAr : subEn)
      : (subEn.isNotEmpty ? subEn : subAr);
  String compoundName(bool ar) => ar
      ? (compoundNameAr.isNotEmpty ? compoundNameAr : compoundNameEn)
      : (compoundNameEn.isNotEmpty ? compoundNameEn : compoundNameAr);
  String developerName(bool ar) => ar
      ? (developerNameAr.isNotEmpty ? developerNameAr : developerNameEn)
      : (developerNameEn.isNotEmpty ? developerNameEn : developerNameAr);
}

/// What `/promotions/:id` adds to a [PromotionItem].
class PromotionDetail {
  final String? videoUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<Map<String, dynamic>> units;
  const PromotionDetail({
    this.videoUrl,
    this.startsAt,
    this.endsAt,
    this.units = const [],
  });
}

class Suggestions {
  final List<Map<String, dynamic>> compounds;
  final List<Map<String, dynamic>> developers;
  final List<Map<String, dynamic>> areas;
  const Suggestions(this.compounds, this.developers, this.areas);
  static const empty = Suggestions([], [], []);
  bool get isEmpty => compounds.isEmpty && developers.isEmpty && areas.isEmpty;
}

/// All Search calls. Properties stay in the legacy vocabulary (the property model still reads
/// `project`); everything else is new and sent as API v2.
class PropertyFacets {
  final Map<String, int> types;
  final Map<String, int> finishings;
  final int launch;
  final int offer;
  const PropertyFacets({
    this.types = const {},
    this.finishings = const {},
    this.launch = 0,
    this.offer = 0,
  });

  factory PropertyFacets.fromJson(Map<String, dynamic> j) {
    Map<String, int> counts(dynamic v) => v is Map
        ? {for (final e in v.entries) '${e.key}': _i(e.value)}
        : const {};
    return PropertyFacets(
      types: counts(j['types']),
      finishings: counts(j['finishings']),
      launch: _i(j['launch']),
      offer: _i(j['offer']),
    );
  }
}

class SearchApi {
  final ApiClient client;
  SearchApi(this.client);

  List<Map<String, dynamic>> _list(dynamic data) => data is List
      ? data.whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];

  Future<SearchPage20> properties(
    SearchFilters f, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await client.get(
      '/properties',
      queryParams: {
        ...f.toQuery(),
        ...f.sortQuery(),
        'page': page,
        'limit': limit,
      },
    );
    final pg = res.data['pagination'];
    return SearchPage20(
      _list(res.data['data']),
      pg is Map ? _i(pg['total']) : 0,
      pg is Map ? _i(pg['pages']) : 0,
    );
  }

  /// Listing counts for the filter sheet: by type and finishing, and how many are launches / offers.
  Future<PropertyFacets> facets() async {
    final res = await client.get('/properties/facets');
    return PropertyFacets.fromJson(
      res.data['data'] is Map<String, dynamic>
          ? res.data['data'] as Map<String, dynamic>
          : const {},
    );
  }

  Future<int> count(SearchFilters f) async {
    final res = await client.get('/properties/count', queryParams: f.toQuery());
    return _i(res.data['data']?['count']);
  }

  Future<List<RelaxSuggestion>> relax(SearchFilters f) async {
    final res = await client.get('/properties/relax', queryParams: f.toQuery());
    final s = res.data['data']?['suggestions'];
    return _list(s).map(RelaxSuggestion.fromJson).toList();
  }

  /// One page of developers (biggest first), searchable by name. `total` is the full count.
  Future<({List<DeveloperSummary> items, int total})> developersPage({
    int page = 1,
    int limit = 20,
    String q = '',
  }) async {
    final res = await client.get(
      '/developers/summary',
      queryParams: {
        'page': page,
        'limit': limit,
        if (q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return (
      items: _list(res.data['data']).map(DeveloperSummary.fromJson).toList(),
      total: (res.data['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<DeveloperSummary>> developers({String? q, int? limit}) async {
    final res = await client.get(
      '/developers/summary',
      queryParams: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (limit != null) 'limit': limit,
      },
    );
    return _list(res.data['data']).map(DeveloperSummary.fromJson).toList();
  }

  Future<List<PromotionItem>> promotions({String? type, int limit = 30}) async {
    final res = await client.get(
      '/promotions',
      queryParams: {if (type != null) 'type': type, 'limit': limit},
      headers: ApiClient.apiV2,
    );
    return _list(res.data['data']).map(PromotionItem.fromJson).toList();
  }

  /// One launch or offer with what the list leaves out: its video and the primary units it is about.
  Future<PromotionDetail> promotion(int id) async {
    final res = await client.get('/promotions/$id', headers: ApiClient.apiV2);
    final d = (res.data['data'] ?? const {}) as Map<String, dynamic>;
    final units = d['properties'] is List
        ? (d['properties'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    return PromotionDetail(
      videoUrl: _s(d['video_url']),
      startsAt: d['starts_at'] is String
          ? DateTime.tryParse(d['starts_at'] as String)
          : null,
      endsAt: d['ends_at'] is String
          ? DateTime.tryParse(d['ends_at'] as String)
          : null,
      units: units,
    );
  }

  Future<List<AreaItem>> areas() async {
    final res = await client.get('/areas');
    return _list(res.data['data']).map(AreaItem.fromJson).toList();
  }

  /// One page of live compounds, searchable by compound or developer name and narrowed by area.
  Future<({List<Map<String, dynamic>> items, int total})> compoundsPage({
    int page = 1,
    int limit = 20,
    String q = '',
    int? areaId,
  }) async {
    final res = await client.get(
      '/compounds',
      queryParams: {
        'page': page,
        'limit': limit,
        if (q.isNotEmpty) 'q': q,
        'area_id': ?areaId,
      },
      headers: ApiClient.apiV2,
    );
    return (
      items: _list(res.data['data']),
      total: (res.data['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// Live compounds for the compound picker. [q] searches by compound or
  /// developer name server-side — there are 800+ compounds, far more than
  /// any fixed page, so a name typed for an older one must reach the server.
  Future<List<Map<String, dynamic>>> compounds({
    String? q,
    int limit = 60,
  }) async {
    final res = await client.get(
      '/compounds',
      queryParams: {
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
      headers: ApiClient.apiV2,
    );
    return _list(res.data['data']);
  }

  /// A single compound by id, for resolving a display name (e.g. the admin
  /// news editor, which only stores the id).
  Future<Map<String, dynamic>?> compoundById(int id) async {
    try {
      final res = await client.get('/compounds/$id', headers: ApiClient.apiV2);
      return res.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// A single developer by id — see [compoundById].
  Future<Map<String, dynamic>?> developerById(int id) async {
    try {
      final res = await client.get('/developers/$id', headers: ApiClient.apiV2);
      return res.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Suggestions> suggest(String q) async {
    final res = await client.get(
      '/search/suggest',
      queryParams: {'q': q},
      headers: ApiClient.apiV2,
    );
    final d = res.data['data'];
    if (d is! Map) return Suggestions.empty;
    return Suggestions(
      _list(d['compounds']),
      _list(d['developers']),
      _list(d['areas']),
    );
  }
}
