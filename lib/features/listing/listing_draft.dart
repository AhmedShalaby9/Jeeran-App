import 'package:image_picker/image_picker.dart';

import '../../core/storage/app_storage.dart';

/// The compound a listing belongs to, as the picker and the review show it.
class CompoundRef {
  final int id;
  final String nameAr, nameEn;
  final String? developerAr, developerEn, areaAr, areaEn;
  const CompoundRef(
    this.id,
    this.nameAr,
    this.nameEn, {
    this.developerAr,
    this.developerEn,
    this.areaAr,
    this.areaEn,
  });

  factory CompoundRef.fromJson(Map<String, dynamic> j) {
    String? s(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final dev = j['developer'] is Map ? j['developer'] as Map : const {};
    final area = j['area'] is Map ? j['area'] as Map : const {};
    final ar = s(j['name_ar']);
    final en = s(j['name_en']);
    return CompoundRef(
      (j['id'] as num).toInt(),
      ar ?? en ?? '',
      en ?? ar ?? '',
      developerAr: s(j['developer_ar']) ?? s(dev['name_ar']),
      developerEn: s(j['developer_en']) ?? s(dev['name_en']),
      areaAr: s(j['area_ar']) ?? s(area['name_ar']),
      areaEn: s(j['area_en']) ?? s(area['name_en']),
    );
  }

  String name(bool ar) => ar ? nameAr : nameEn;
  String sub(bool ar) => [
    ar ? (developerAr ?? developerEn) : (developerEn ?? developerAr),
    ar ? (areaAr ?? areaEn) : (areaEn ?? areaAr),
  ].whereType<String>().join(' · ');
}

/// What the seller has told us so far. The form edits it directly; the assistant fills it from words.
/// Keys in [ai] are the fields the assistant filled and the seller has not touched yet.
class ListingDraft {
  String? type; // apartment | villa | townhouse | chalet | duplex | studio …
  String status = 'for_sale'; // for_sale | for_rent | for_rent_furnished

  /// primary = bought from the developer · resale = from an owner. Null = the default for who is listing.
  String? listingType;
  CompoundRef? compound;
  int bedrooms = 2;
  bool bedroomsSet = false;
  int bathrooms = 1;
  bool bathroomsSet = false;
  String size = '';
  String level = '';
  String? finishing;
  String? delivery; // 'ready' or a year as text
  String? view;
  final Set<String> extras = {}; // roof · beach access · corner unit · parking
  String garden = ''; // m²
  String land = ''; // m², villas: the plot (size is the built-up area)
  bool? outdoor; // shops: has an outdoor area (null = not answered)
  String outdoorSize = ''; // m²
  bool? groundGarden; // apartments, chalets, duplexes: a ground-floor unit with a garden? (null = not answered)
  String maintenance = ''; // as the seller words it
  String price = '';
  String payment = 'cash'; // cash | installments
  String down = '';
  String downAmount =
      ''; // a resale gives its down payment as an amount (EGP), not a percentage
  String years = '';
  String title = '';
  String description = '';

  /// The same title and description in the OTHER language than the one above (the app's language is the first). Both are
  /// shown and editable; when this one is empty the server translates what was written.
  String titleAlt = '';
  String descriptionAlt = '';
  final List<XFile> photos = [];
  XFile? video;
  XFile? floorPlan;
  final Set<String> ai = {};

  /// What the seller wrote or said to the assistant, so the written title and description can use details
  /// that have no field of their own ("ground floor with a garden").
  final List<String> said = [];

  /// How buyers reach the lister: filled from the account when the review opens, editable there.
  String contactName = '';
  String contactPhone = '';
  String contactEmail = '';

  /// Editing a live listing: its id, the photos already on the server, and what we must not clobber.
  int? editingId;
  final List<String> existingImages = [];
  String? origPayment;

  /// A cover Jeeran made from the seller's photos (a URL on our storage). Null = the first photo is the cover.
  String? coverUrl;
  bool get coverIsAi => coverUrl != null;
  int get photoCount => existingImages.length + photos.length;

  static const types = [
    'apartment',
    'villa',
    'townhouse',
    'twinhouse',
    'chalet',
    'duplex',
    'studio',
    'penthouse',
    'loft',
    'cabin',
    'family_house',
    'marina_apartment',
    'office',
    'clinic',
    'shop',
    'land',
  ];
  static const listingTypes = ['resale', 'primary'];

  /// Types that come with their own garden.
  static const gardenTypes = [
    'villa',
    'townhouse',
    'twinhouse',
    'penthouse',
    'family_house',
    'cabin',
  ];
  /// Types where the seller says whether it is a ground-floor unit with a garden, then how big.
  static const gardenChoiceTypes = ['apartment', 'chalet', 'duplex'];
  /// Every kind of villa: the plot and the built-up area are both asked.
  static const villaTypes = ['villa', 'townhouse', 'twinhouse', 'family_house'];
  static const extraFeatures = [
    'roof',
    'beach_access',
    'corner_unit',
    'parking',
  ];
  static const finishings = [
    'core_shell',
    'semi_finished',
    'fully_finished',
    'furnished',
  ];

  /// Ready, then the next three years (the last reads "+"): it moves on with the calendar.
  static List<String> get deliveries {
    final y = DateTime.now().year;
    return ['ready', '${y + 1}', '${y + 2}', '${y + 3}'];
  }

  static const views = [
    'sea_view',
    'lagoon_view',
    'pool_view',
    'private_garden',
    'golf_view',
    'parking_view',
    'street_view',
  ];

  double? get priceValue => double.tryParse(price.replaceAll(',', '').trim());
  double? get sizeValue => double.tryParse(size.trim());
  double? get gardenValue => double.tryParse(garden.trim());
  bool get hasGarden => gardenTypes.contains(type) || (gardenChoiceTypes.contains(type) && groundGarden == true);
  bool get asksLand => villaTypes.contains(type);
  bool get asksOutdoor => type == 'shop';
  double? get landValue => double.tryParse(land.trim());
  double? get outdoorValue => double.tryParse(outdoorSize.trim());
  bool get asksGarden => gardenChoiceTypes.contains(type);
  bool get isRent => status != 'for_sale';

  /// A resale (what the lister is selling is their own contract): the price is the total contract value and the down
  /// payment is an amount. Everyone defaults to resale — the far more common case — unless the lister chose primary.
  bool get isResale {
    var admin = false;
    try {
      admin = AppStorage.isAdmin;
    } catch (_) {} // (storage not open, e.g. in a plain unit test: sellers' default)
    return effectiveListingType(admin: admin) == 'resale';
  }
  double? get downAmountValue =>
      double.tryParse(downAmount.replaceAll(',', '').trim());
  /// Only Jeeran admins can list a primary (developer) unit; everyone else always lists resale.
  /// Admins default to resale too — most of what they list is a resale unit — unless they pick primary.
  String effectiveListingType({required bool admin}) =>
      admin ? (listingType ?? 'resale') : 'resale';
  bool get noRooms => const ['land', 'shop', 'office', 'clinic'].contains(type);

  bool get basicsValid => type != null && compound != null;
  bool get detailsValid => (sizeValue ?? 0) > 0;
  bool get priceValid => (priceValue ?? 0) > 0;
  bool get mediaValid =>
      photoCount > 0 &&
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty;

  /// Monthly instalment when the plan is complete; null otherwise.
  ({double down, double monthly, double total})? get plan {
    final p = priceValue;
    final y = double.tryParse(years);
    if (payment != 'installments' || p == null || y == null || y <= 0)
      return null;
    final double dn;
    if (isResale) {
      // the amount the lister gave; or, when only a percentage is known (the assistant heard "10% down"), that share of the price
      final pct = double.tryParse(down);
      final a = downAmountValue ?? (pct == null ? null : p * pct / 100);
      if (a == null || a < 0 || a > p) return null;
      dn = a;
    } else {
      final d = double.tryParse(down);
      if (d == null) return null;
      dn = p * d / 100;
    }
    return (down: dn, monthly: (p - dn) / (y * 12), total: p);
  }

  /// Merge what the server's parser returned over this draft; remember what it filled.
  void apply(
    Map<String, dynamic> d,
    CompoundRef? compoundRef,
    Iterable<dynamic> filled,
  ) {
    String? s(dynamic v) => v == null ? null : '$v';
    if (d['type'] != null) type = s(d['type']);
    if (d['status'] != null) status = s(d['status'])!;
    if (compoundRef != null) compound = compoundRef;
    if (d['bedrooms'] is num) {
      bedrooms = (d['bedrooms'] as num).toInt();
      bedroomsSet = true;
    }
    if (d['bathrooms'] is num) {
      bathrooms = (d['bathrooms'] as num).toInt();
      bathroomsSet = true;
    }
    if (d['size'] is num) size = _trim(d['size'] as num);
    if (d['level'] != null) level = s(d['level'])!;
    if (d['land_size'] is num) land = _trim(d['land_size'] as num);
    if (d['garden_size'] is num) garden = _trim(d['garden_size'] as num);
    if (d['has_garden'] is bool) {
      groundGarden = d['has_garden'] as bool;
    } else if (d['garden_size'] is num) {
      groundGarden = true;
    }
    if (d['outdoor_size'] is num) outdoorSize = _trim(d['outdoor_size'] as num);
    if (d['has_outdoor'] is bool) {
      outdoor = d['has_outdoor'] as bool;
    } else if (d['outdoor_size'] is num) {
      outdoor = true;
    }
    if (d['finishing'] != null) finishing = s(d['finishing']);
    if (d['delivery'] != null) delivery = s(d['delivery']);
    if (d['view'] != null) view = s(d['view']);
    if (d['price'] is num) price = _trim(d['price'] as num);
    if (d['payment'] != null) payment = s(d['payment'])!;
    if (d['down_payment_percent'] is num)
      down = _trim(d['down_payment_percent'] as num);
    if (d['installment_years'] is num)
      years = _trim(d['installment_years'] as num);
    for (final k in filled) {
      ai.add(switch ('$k') {
        'compound_id' => 'compound',
        'bedrooms' => 'bedrooms',
        'down_payment_percent' => 'down',
        'land_size' => 'land',
        'garden_size' || 'has_garden' => 'garden',
        'outdoor_size' || 'has_outdoor' => 'outdoor',
        'installment_years' => 'years',
        final other => other,
      });
    }
  }

  /// The parser's view of this draft, to send back with the next sentence.
  Map<String, dynamic> toParserJson() => {
    'type': ?type,
    'status': status,
    if (compound != null) 'compound_id': compound!.id,
    if (bedroomsSet) 'bedrooms': bedrooms,
    if (bathroomsSet) 'bathrooms': bathrooms,
    if (sizeValue != null) 'size': sizeValue,
    if (level.trim().isNotEmpty) 'level': level.trim(),
    if (landValue != null) 'land_size': landValue,
    if (groundGarden != null) 'has_garden': groundGarden,
    if (gardenValue != null) 'garden_size': gardenValue,
    if (outdoor != null) 'has_outdoor': outdoor,
    if (outdoorValue != null) 'outdoor_size': outdoorValue,
    'finishing': ?finishing,
    if (delivery != null)
      'delivery': delivery == 'ready' ? 'ready' : int.tryParse(delivery!),
    'view': ?view,
    if (priceValue != null) 'price': priceValue,
    if (price.isNotEmpty || payment == 'installments') 'payment': payment,
    if (double.tryParse(down) != null)
      'down_payment_percent': double.parse(down),
    if (int.tryParse(years) != null) 'installment_years': int.parse(years),
  };

  static String? _c(String mine, String? fallback) {
    final v = mine.trim();
    if (v.isNotEmpty) return v;
    final f = fallback?.trim();
    return f == null || f.isEmpty ? null : f;
  }

  /// `POST /properties` body (images are uploaded first and passed in).
  Map<String, dynamic> toBody({
    required List<String> images,
    required bool ar,
    required bool admin,
    String? videoUrl,
    String? floorPlanUrl,
    String? agentName,
    String? agentPhone,
    String? agentEmail,
  }) {
    final editing = editingId != null;
    String? deliveryDate;
    if (delivery == 'ready') {
      final n = DateTime.now();
      deliveryDate =
          '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    } else if (delivery != null) {
      deliveryDate = '$delivery-12-31';
    }
    final lang = ar ? 'ar' : 'en';
    final otherLang = ar ? 'en' : 'ar';
    return {
      'compound_id': compound!.id,
      'property_type': type,
      'property_status': status,
      'listing_type': effectiveListingType(admin: admin),
      if (!editing) 'country': 'egypt',
      'price': priceValue,
      'size': sizeValue,
      if (!noRooms) 'bedrooms': bedrooms,
      if (!noRooms) 'bathrooms': bathrooms,
      // written in the seller's language; the server translates the other side
      'title_$lang': title.trim(),
      'content_$lang': description.trim(),
      if (titleAlt.trim().isNotEmpty) 'title_$otherLang': titleAlt.trim(),
      if (descriptionAlt.trim().isNotEmpty)
        'content_$otherLang': descriptionAlt.trim(),
      if (level.trim().isNotEmpty) 'level_ar': level.trim(),
      if (level.trim().isNotEmpty) 'level_en': level.trim(),
      'finishing': ?finishing,
      'delivery_date': ?deliveryDate,
      // a rental has no payment plan; an edit leaves a plan we cannot show (e.g. mortgage) alone unless the seller changed it
      if (!isRent && (!editing || origPayment != payment))
        'payment_options': [payment],
      if (!isRent &&
          payment == 'installments' &&
          effectiveListingType(admin: admin) == 'resale' &&
          downAmountValue != null)
        'down_payment_amount':
            downAmountValue // (the server keeps the percentage in step with it)
      else if (!isRent &&
          payment == 'installments' &&
          double.tryParse(down) != null)
        'down_payment_percent': double.parse(down),
      if (!isRent && payment == 'installments' && int.tryParse(years) != null)
        'installment_years': int.parse(years),
      if (view != null || extras.isNotEmpty) 'features': [?view, ...extras],
      if (asksLand && landValue != null) 'land_size': landValue,
      if (asksOutdoor && outdoor != null) 'has_outdoor': outdoor,
      if (asksOutdoor && outdoor == true && outdoorValue != null) 'outdoor_size': outdoorValue,
      if (asksGarden && groundGarden != null) 'has_garden': groundGarden,
      if (hasGarden && gardenValue != null) 'garden_size': gardenValue,
      if (maintenance.trim().isNotEmpty) 'maintenance_ar': maintenance.trim(),
      if (maintenance.trim().isNotEmpty) 'maintenance_en': maintenance.trim(),
      // a generated cover goes first; the flag lets buyers see it is one
      'images': [?coverUrl, ...images],
      'cover_is_ai': coverIsAi,
      'video_url': ?videoUrl,
      'floor_plan': ?floorPlanUrl,
      // what the lister confirmed on the review; the account's details only when that was left empty
      if (_c(contactName, agentName) != null)
        'agent_name': _c(contactName, agentName),
      if (_c(contactPhone, agentPhone) != null)
        'agent_mobile': _c(contactPhone, agentPhone),
      if (_c(contactPhone, agentPhone) != null)
        'agent_whatsapp': _c(contactPhone, agentPhone),
      if (_c(contactEmail, agentEmail) != null)
        'agent_email': _c(contactEmail, agentEmail),
    };
  }

  // ── saved on the phone so a half-finished listing survives ──
  Map<String, dynamic> toStore() => {
    ...toParserJson(),
    'bedroomsSet': bedroomsSet,
    'bathroomsSet': bathroomsSet,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'size': size,
    'price': price,
    'payment': payment,
    'down': down,
    'downAmount': downAmount,
    'years': years,
    'level': level,
    'listingType': listingType,
    'garden': garden,
    'groundGarden': groundGarden,
    'land': land,
    'outdoor': outdoor,
    'outdoorSize': outdoorSize,
    'maintenance': maintenance,
    'extras': extras.toList(),
    'delivery': delivery,
    'title': title,
    'description': description,
    'titleAlt': titleAlt,
    'descriptionAlt': descriptionAlt,
    if (compound != null)
      'compound': {
        'id': compound!.id,
        'name_ar': compound!.nameAr,
        'name_en': compound!.nameEn,
        'developer_ar': compound!.developerAr,
        'developer_en': compound!.developerEn,
        'area_ar': compound!.areaAr,
        'area_en': compound!.areaEn,
      },
  };

  static ListingDraft fromStore(Map<String, dynamic> j) {
    final d = ListingDraft();
    d.type = j['type'] as String?;
    d.status = (j['status'] as String?) ?? 'for_sale';
    if (j['compound'] is Map) {
      d.compound = CompoundRef.fromJson(
        Map<String, dynamic>.from(j['compound'] as Map),
      );
    }
    d.bedrooms = (j['bedrooms'] as num?)?.toInt() ?? 2;
    d.bedroomsSet = j['bedroomsSet'] == true;
    d.bathrooms = (j['bathrooms'] as num?)?.toInt() ?? 1;
    d.bathroomsSet = j['bathroomsSet'] == true;
    d.size = '${j['size'] ?? ''}';
    d.level = '${j['level'] ?? ''}';
    d.listingType = j['listingType'] as String?;
    d.garden = '${j['garden'] ?? ''}';
    d.groundGarden = j['groundGarden'] as bool?;
    d.land = '${j['land'] ?? ''}';
    d.outdoor = j['outdoor'] as bool?;
    d.outdoorSize = '${j['outdoorSize'] ?? ''}';
    d.maintenance = '${j['maintenance'] ?? ''}';
    if (j['extras'] is List)
      d.extras.addAll((j['extras'] as List).whereType<String>());
    d.finishing = j['finishing'] as String?;
    d.delivery = j['delivery'] == null ? null : '${j['delivery']}';
    d.view = j['view'] as String?;
    d.price = '${j['price'] ?? ''}';
    d.payment = (j['payment'] as String?) ?? 'cash';
    d.down = '${j['down'] ?? ''}';
    d.downAmount = '${j['downAmount'] ?? ''}';
    d.years = '${j['years'] ?? ''}';
    d.title = '${j['title'] ?? ''}';
    d.description = '${j['description'] ?? ''}';
    d.titleAlt = '${j['titleAlt'] ?? ''}';
    d.descriptionAlt = '${j['descriptionAlt'] ?? ''}';
    return d;
  }

  /// A live listing (`GET /properties/:id`, v2) turned back into a draft the form can edit.
  static ListingDraft fromProperty(Map<String, dynamic> j, {required bool ar}) {
    String? s(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    num? n(dynamic v) => v is num ? v : num.tryParse('${v ?? ''}');
    final d = ListingDraft();
    d.editingId = (j['id'] as num).toInt();
    d.type = s(j['property_type']);
    final st = s(j['property_status']);
    d.status = const ['for_sale', 'for_rent', 'for_rent_furnished'].contains(st)
        ? st!
        : 'for_sale';
    d.listingType = s(j['listing_type']);
    if (j['compound'] is Map) {
      d.compound = CompoundRef.fromJson(
        Map<String, dynamic>.from(j['compound'] as Map),
      );
    }
    final beds = n(j['bedrooms']);
    if (beds != null) {
      d.bedrooms = beds.toInt();
      d.bedroomsSet = true;
    }
    final baths = n(j['bathrooms']);
    if (baths != null) {
      d.bathrooms = baths.toInt();
      d.bathroomsSet = true;
    }
    final size = n(j['size']);
    if (size != null) d.size = _trim(size);
    d.level =
        s(ar ? j['level_ar'] : j['level_en']) ??
        s(j['level_en']) ??
        s(j['level_ar']) ??
        '';
    d.finishing = s(j['finishing']);
    final dd = s(j['delivery_date']);
    if (dd != null) {
      final t = DateTime.tryParse(dd);
      if (t != null)
        d.delivery = t.isAfter(DateTime.now()) ? '${t.year}' : 'ready';
    }
    final feats = (j['features'] is List)
        ? (j['features'] as List).map((e) => '$e').toList()
        : const <String>[];
    d.view = views
        .where(feats.contains)
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => null);
    d.extras.addAll(extraFeatures.where(feats.contains));
    final garden = n(j['garden_size']);
    if (garden != null) d.garden = _trim(garden);
    final land = n(j['land_size']);
    if (land != null) d.land = _trim(land);
    final outdoorSize = n(j['outdoor_size']);
    if (outdoorSize != null) d.outdoorSize = _trim(outdoorSize);
    if (j['has_outdoor'] is bool) {
      d.outdoor = j['has_outdoor'] as bool;
    } else if (outdoorSize != null && outdoorSize > 0) {
      d.outdoor = true;
    }
    if (j['has_garden'] is bool) {
      d.groundGarden = j['has_garden'] as bool;
    } else if (garden != null && garden > 0) {
      d.groundGarden = true; // a size was given: it has a garden
    }
    d.maintenance =
        s(ar ? j['maintenance_ar'] : j['maintenance_en']) ??
        s(j['maintenance_en']) ??
        s(j['maintenance_ar']) ??
        '';
    final price = n(j['price']);
    if (price != null) d.price = _trim(price);
    final pay = (j['payment_options'] is List)
        ? (j['payment_options'] as List).map((e) => '$e').toList()
        : const <String>[];
    d.payment = pay.contains('installments') ? 'installments' : 'cash';
    d.origPayment = d.payment;
    final down = n(j['down_payment_percent']);
    if (down != null) d.down = _trim(down);
    final downAmt = n(j['down_payment_amount']);
    if (downAmt != null) d.downAmount = _trim(downAmt);
    final yrs = n(j['installment_years']);
    if (yrs != null) d.years = _trim(yrs);
    d.title =
        s(ar ? j['title_ar'] : j['title_en']) ??
        s(j['title_en']) ??
        s(j['title_ar']) ??
        '';
    d.description =
        s(ar ? j['content_ar'] : j['content_en']) ??
        s(j['content_en']) ??
        s(j['content_ar']) ??
        '';
    d.contactName = s(j['agent_name']) ?? '';
    d.contactPhone = s(j['agent_mobile']) ?? '';
    d.contactEmail = s(j['agent_email']) ?? '';
    d.titleAlt = s(ar ? j['title_en'] : j['title_ar']) ?? '';
    d.descriptionAlt = s(ar ? j['content_en'] : j['content_ar']) ?? '';
    final imgs = (j['images'] is List)
        ? (j['images'] as List).whereType<String>().toList()
        : <String>[];
    if (j['cover_is_ai'] == true && imgs.isNotEmpty) {
      d.coverUrl = imgs.first;
      d.existingImages.addAll(imgs.skip(1));
    } else {
      d.existingImages.addAll(imgs);
    }
    return d;
  }

  bool get isBlank =>
      type == null &&
      compound == null &&
      size.isEmpty &&
      price.isEmpty &&
      title.isEmpty;

  static String _trim(num n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}
