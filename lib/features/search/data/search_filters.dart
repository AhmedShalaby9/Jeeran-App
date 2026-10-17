import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

import 'search_api.dart' show PromotionItem;

/// Everything the Search screens can narrow by. One immutable value so the list, the live
/// count and the "widen it" suggestions can never disagree: they all send [toQuery].
class SearchFilters extends Equatable {
  final String q;
  final String? status; // for_sale | for_rent | for_rent_furnished
  final String?
  saleType; // primary (from the developer) | resale (from an owner)
  final Set<String> types;
  final String? beds; // '3' | '5+'
  final String? baths;
  final int? minPrice;
  final int? maxPrice;
  final int? minSize;
  final int? maxSize;
  final String? delivery; // ready | 2026 | 2027 | 2028 | 2029+
  final String? finishing;
  final String? payment;
  final Set<String> amenities;
  final int? areaId;
  final String? areaName; // display only
  final int? promotionId; // the units of one launch/offer
  final String? promotionName; // display only
  final int? compoundId;
  final String? compoundName; // display only
  final int? developerId;
  final String? developerName; // display only
  final bool featured;
  final bool verifiedOnly;
  final bool launch; // developer launches only
  final bool offer; // units with an offer only
  final String?
  maxDown; // the biggest down payment (%) the buyer accepts: 0 | 5 | 10 | 20
  final String? minYears; // the shortest instalment length (years): 5 | 8 | 10
  final String sort; // newest | price_asc | price_desc | largest | discount

  const SearchFilters({
    this.q = '',
    this.status,
    this.saleType,
    this.types = const {},
    this.beds,
    this.baths,
    this.minPrice,
    this.maxPrice,
    this.minSize,
    this.maxSize,
    this.delivery,
    this.finishing,
    this.payment,
    this.amenities = const {},
    this.areaId,
    this.areaName,
    this.promotionId,
    this.promotionName,
    this.compoundId,
    this.compoundName,
    this.developerId,
    this.developerName,
    this.featured = false,
    this.verifiedOnly = false,
    this.launch = false,
    this.offer = false,
    this.maxDown,
    this.minYears,
    this.sort = 'newest',
  });

  /// What tapping a launch/offer shows: exactly its units when it has some, else its whole compound.
  static SearchFilters forPromotion(PromotionItem p, {required bool ar}) =>
      p.propertiesCount > 0
      ? SearchFilters(promotionId: p.id, promotionName: p.title(ar))
      : SearchFilters(
          compoundId: p.compoundId,
          compoundName: p.compoundName(ar),
        );

  static const sorts = [
    'newest',
    'price_asc',
    'price_desc',
    'largest',
    'discount',
  ];

  /// Query parameters for `/properties`, `/properties/count` and `/properties/relax`.
  Map<String, dynamic> toQuery() => {
    if (q.trim().isNotEmpty) 'q': q.trim(),
    if (status != null) 'status': status,
    if (saleType != null) 'listing_type': saleType,
    if (types.isNotEmpty) 'type': types.join(','),
    if (beds != null) 'bedrooms': beds,
    if (baths != null) 'bathrooms': baths,
    if (minPrice != null) 'min_price': minPrice,
    if (maxPrice != null) 'max_price': maxPrice,
    if (minSize != null) 'min_size': minSize,
    if (maxSize != null) 'max_size': maxSize,
    if (delivery != null) 'delivery': deliveryQuery(delivery!),
    if (finishing != null) 'finishing': finishing,
    if (launch) 'launch': '1',
    if (offer) 'offer': '1',
    if (maxDown != null) 'down_max': maxDown,
    if (minYears != null) 'years_min': minYears,
    if (payment != null) 'payment': payment,
    if (amenities.isNotEmpty) 'amenities': amenities.join(','),
    if (areaId != null) 'area_id': areaId,
    if (promotionId != null) 'promotion_id': promotionId,
    if (compoundId != null) 'compound_id': compoundId,
    if (developerId != null) 'developer_id': developerId,
    if (featured) 'is_featured': 'true',
    if (verifiedOnly) 'verified_only': 'true',
  };

  /// `sort` / `order` for the list only (the count ignores ordering).
  Map<String, dynamic> sortQuery() => switch (sort) {
    'price_asc' => {'sort': 'price', 'order': 'ASC'},
    'price_desc' => {'sort': 'price', 'order': 'DESC'},
    'largest' => {'sort': 'size', 'order': 'DESC'},
    'discount' => {'sort': 'offer_discount_percent', 'order': 'DESC'},
    _ => {'sort': 'created_at', 'order': 'DESC'},
  };

  /// True when anything narrows the list (the sort alone does not).
  bool get isActive => toQuery().isNotEmpty;

  /// Number of narrowing conditions, for the badge on the Filters button.
  int get activeCount {
    var n = 0;
    if (q.trim().isNotEmpty) n++;
    if (status != null) n++;
    if (saleType != null) n++;
    n += types.length;
    if (beds != null) n++;
    if (baths != null) n++;
    if (minPrice != null || maxPrice != null) n++;
    if (minSize != null || maxSize != null) n++;
    if (delivery != null) n++;
    if (finishing != null) n++;
    if (payment != null) n++;
    n += amenities.length;
    if (areaId != null) n++;
    if (promotionId != null) n++;
    if (compoundId != null) n++;
    if (developerId != null) n++;
    if (featured) n++;
    if (verifiedOnly) n++;
    if (launch) n++;
    if (offer) n++;
    if (maxDown != null) n++;
    if (minYears != null) n++;
    return n;
  }

  static const _nil = Object();

  SearchFilters copyWith({
    String? q,
    Object? status = _nil,
    Object? saleType = _nil,
    Set<String>? types,
    Object? beds = _nil,
    Object? baths = _nil,
    Object? minPrice = _nil,
    Object? maxPrice = _nil,
    Object? minSize = _nil,
    Object? maxSize = _nil,
    Object? delivery = _nil,
    Object? finishing = _nil,
    Object? payment = _nil,
    Set<String>? amenities,
    Object? areaId = _nil,
    Object? areaName = _nil,
    Object? promotionId = _nil,
    Object? promotionName = _nil,
    Object? compoundId = _nil,
    Object? compoundName = _nil,
    Object? developerId = _nil,
    Object? developerName = _nil,
    bool? featured,
    bool? verifiedOnly,
    bool? launch,
    bool? offer,
    Object? maxDown = _nil,
    Object? minYears = _nil,
    String? sort,
  }) => SearchFilters(
    q: q ?? this.q,
    status: status == _nil ? this.status : status as String?,
    saleType: saleType == _nil ? this.saleType : saleType as String?,
    types: types ?? this.types,
    beds: beds == _nil ? this.beds : beds as String?,
    baths: baths == _nil ? this.baths : baths as String?,
    minPrice: minPrice == _nil ? this.minPrice : minPrice as int?,
    maxPrice: maxPrice == _nil ? this.maxPrice : maxPrice as int?,
    minSize: minSize == _nil ? this.minSize : minSize as int?,
    maxSize: maxSize == _nil ? this.maxSize : maxSize as int?,
    delivery: delivery == _nil ? this.delivery : delivery as String?,
    finishing: finishing == _nil ? this.finishing : finishing as String?,
    payment: payment == _nil ? this.payment : payment as String?,
    amenities: amenities ?? this.amenities,
    areaId: areaId == _nil ? this.areaId : areaId as int?,
    areaName: areaName == _nil ? this.areaName : areaName as String?,
    promotionId: promotionId == _nil ? this.promotionId : promotionId as int?,
    promotionName: promotionName == _nil
        ? this.promotionName
        : promotionName as String?,
    compoundId: compoundId == _nil ? this.compoundId : compoundId as int?,
    compoundName: compoundName == _nil
        ? this.compoundName
        : compoundName as String?,
    developerId: developerId == _nil ? this.developerId : developerId as int?,
    developerName: developerName == _nil
        ? this.developerName
        : developerName as String?,
    featured: featured ?? this.featured,
    verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    launch: launch ?? this.launch,
    offer: offer ?? this.offer,
    maxDown: maxDown == _nil ? this.maxDown : maxDown as String?,
    minYears: minYears == _nil ? this.minYears : minYears as String?,
    sort: sort ?? this.sort,
  );

  /// Drop the condition the server calls [name] (see `activeFilters` in the backend).
  SearchFilters without(String name) => switch (name) {
    'q' => copyWith(q: ''),
    'type' => copyWith(types: const {}),
    'status' => copyWith(status: null),
    'listing_type' => copyWith(saleType: null),
    'promotion' => copyWith(promotionId: null, promotionName: null),
    'compound' => copyWith(compoundId: null, compoundName: null),
    'developer' => copyWith(developerId: null, developerName: null),
    'area' => copyWith(areaId: null, areaName: null),
    'price_min' => copyWith(minPrice: null),
    'price_max' => copyWith(maxPrice: null),
    'bedrooms' => copyWith(beds: null),
    'bathrooms' => copyWith(baths: null),
    'size_min' => copyWith(minSize: null),
    'size_max' => copyWith(maxSize: null),
    'delivery' => copyWith(delivery: null),
    'finishing' => copyWith(finishing: null),
    'payment' => copyWith(payment: null),
    'amenities' => copyWith(amenities: const {}),
    'featured' => copyWith(featured: false),
    'verified' => copyWith(verifiedOnly: false),
    'launch' => copyWith(launch: false),
    'offer' => copyWith(offer: false),
    'down_max' => copyWith(maxDown: null),
    'years_min' => copyWith(minYears: null),
    _ => this,
  };

  Map<String, dynamic> toJson() => {
    'q': q,
    'status': status,
    'saleType': saleType,
    'types': types.toList(),
    'beds': beds,
    'baths': baths,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'minSize': minSize,
    'maxSize': maxSize,
    'delivery': delivery,
    'finishing': finishing,
    'payment': payment,
    'amenities': amenities.toList(),
    'areaId': areaId,
    'areaName': areaName,
    'promotionId': promotionId,
    'promotionName': promotionName,
    'compoundId': compoundId,
    'compoundName': compoundName,
    'developerId': developerId,
    'developerName': developerName,
    'featured': featured,
    'verifiedOnly': verifiedOnly,
    'launch': launch,
    'offer': offer,
    'maxDown': maxDown,
    'minYears': minYears,
    'sort': sort,
  };

  factory SearchFilters.fromJson(Map<dynamic, dynamic> j) {
    Set<String> strings(dynamic v) =>
        v is List ? v.whereType<String>().toSet() : <String>{};
    int? i(dynamic v) => v is num ? v.toInt() : null;
    String? s(dynamic v) => v is String && v.isNotEmpty ? v : null;
    return SearchFilters(
      q: s(j['q']) ?? '',
      status: s(j['status']),
      saleType: s(j['saleType']),
      types: strings(j['types']),
      beds: s(j['beds']),
      baths: s(j['baths']),
      minPrice: i(j['minPrice']),
      maxPrice: i(j['maxPrice']),
      minSize: i(j['minSize']),
      maxSize: i(j['maxSize']),
      delivery: s(j['delivery']),
      finishing: s(j['finishing']),
      payment: s(j['payment']),
      amenities: strings(j['amenities']),
      areaId: i(j['areaId']),
      areaName: s(j['areaName']),
      promotionId: i(j['promotionId']),
      promotionName: s(j['promotionName']),
      compoundId: i(j['compoundId']),
      compoundName: s(j['compoundName']),
      developerId: i(j['developerId']),
      developerName: s(j['developerName']),
      featured: j['featured'] == true,
      verifiedOnly: j['verifiedOnly'] == true,
      launch: j['launch'] == true,
      offer: j['offer'] == true,
      maxDown: s(j['maxDown']),
      minYears: s(j['minYears']),
      sort: SearchFilters.sorts.contains(j['sort'])
          ? j['sort'] as String
          : 'newest',
    );
  }

  @override
  List<Object?> get props => [
    q,
    status,
    saleType,
    types,
    beds,
    baths,
    minPrice,
    maxPrice,
    minSize,
    maxSize,
    delivery,
    finishing,
    payment,
    amenities,
    areaId,
    promotionId,
    compoundId,
    developerId,
    featured,
    verifiedOnly,
    launch,
    offer,
    maxDown,
    minYears,
    sort,
  ];
}

/// Choices shown in the UI, with the keys the API expects.
class SearchOptions {
  SearchOptions._();

  static const statuses = ['for_sale', 'for_rent', 'for_rent_furnished'];
  static const saleTypes = ['primary', 'resale'];
  static const types = [
    'chalet',
    'villa',
    'twinhouse',
    'townhouse',
    'apartment',
    'duplex',
    'studio',
    'land',
    'penthouse',
    'loft',
    'cabin',
    'family_house',
    'office',
    'clinic',
    'shop',
  ];

  /// The four quick-sort chips in Browse list fewer types than the full sheet.
  static const quickTypes = [
    'chalet',
    'villa',
    'twinhouse',
    'townhouse',
    'apartment',
    'duplex',
    'studio',
    'land',
  ];
  static const counts = ['1', '2', '3', '4', '5+'];
  static const deliveries = [
    'ready',
    '2026',
    '2027',
    '2028',
    '2029',
    '2030',
    '2031+',
  ];
  static const downPayments = ['0', '5', '10', '20'];
  static const instalmentYears = ['5', '8', '10'];
  static const finishings = [
    'fully_finished',
    'semi_finished',
    'core_shell',
    'furnished',
  ];
  static const payments = ['cash', 'installments', 'mortgage'];
  static const amenities = [
    'sea_view',
    'pool_view',
    'private_garden',
    'roof',
    'golf_view',
    'beach_access',
    'corner_unit',
    'parking',
  ];

  /// Quick price bands in Browse: label key → (min, max).
  static const priceBands = <String, (int?, int?)>{
    'under_5': (null, 5000000),
    '5_10': (5000000, 10000000),
    '10_15': (10000000, 15000000),
    '15_25': (15000000, 25000000),
    '25_plus': (25000000, null),
  };

  static const priceMin = 1000000;
  static const priceMax = 50000000; // the slider's right end means "no cap"
}

/// "By 2028" means everything delivered up to the end of 2028 (units already ready included);
/// "2031+" means 2031 or later; "ready" is what is delivered today. The server takes a list of those.
String deliveryQuery(String d) {
  final year = int.tryParse(d);
  if (year == null) return d;
  return ['ready', for (var y = 2026; y <= year; y++) '$y'].join(',');
}

/// "Ready", "By 2028" or "2031+" — how a delivery choice reads on a chip.
String deliveryLabel(String d) {
  if (d == 'ready') return 'find.ready'.tr();
  if (int.tryParse(d) != null) return 'find.by_year'.tr(namedArgs: {'y': d});
  return d;
}
