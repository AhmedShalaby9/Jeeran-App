import 'package:image_picker/image_picker.dart';

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
  String status = 'for_sale'; // for_sale | for_rent
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
  String price = '';
  String payment = 'cash'; // cash | installments
  String down = '';
  String years = '';
  String title = '';
  String description = '';
  final List<XFile> photos = [];
  XFile? video;
  XFile? floorPlan;
  final Set<String> ai = {};

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
    'chalet',
    'duplex',
    'studio',
  ];
  static const finishings = [
    'core_shell',
    'semi_finished',
    'fully_finished',
    'furnished',
  ];
  static const deliveries = ['ready', '2027', '2028', '2029'];
  static const views = [
    'sea_view',
    'lagoon_view',
    'pool_view',
    'private_garden',
    'golf_view',
  ];

  double? get priceValue => double.tryParse(price.replaceAll(',', '').trim());
  double? get sizeValue => double.tryParse(size.trim());
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
    final d = double.tryParse(down);
    final y = double.tryParse(years);
    if (payment != 'installments' ||
        p == null ||
        d == null ||
        y == null ||
        y <= 0)
      return null;
    final dn = p * d / 100;
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
    return {
      'compound_id': compound!.id,
      'property_type': type,
      'property_status': status,
      if (!editing) 'listing_type': admin ? 'primary' : 'resale',
      if (!editing) 'country': 'egypt',
      'price': priceValue,
      'size': sizeValue,
      if (!noRooms) 'bedrooms': bedrooms,
      if (!noRooms) 'bathrooms': bathrooms,
      // written in the seller's language; the server translates the other side
      'title_$lang': title.trim(),
      'content_$lang': description.trim(),
      if (level.trim().isNotEmpty) 'level_ar': level.trim(),
      if (level.trim().isNotEmpty) 'level_en': level.trim(),
      'finishing': ?finishing,
      'delivery_date': ?deliveryDate,
      // an edit leaves a plan we cannot show (e.g. mortgage) alone unless the seller changed it
      if (!editing || origPayment != payment) 'payment_options': [payment],
      if (payment == 'installments' && double.tryParse(down) != null)
        'down_payment_percent': double.parse(down),
      if (payment == 'installments' && int.tryParse(years) != null)
        'installment_years': int.parse(years),
      if (view != null) 'features': [view],
      // a generated cover goes first; the flag lets buyers see it is one
      'images': [?coverUrl, ...images],
      'cover_is_ai': coverIsAi,
      'video_url': ?videoUrl,
      'floor_plan': ?floorPlanUrl,
      if (!editing) 'agent_name': ?agentName,
      if (!editing) 'agent_mobile': ?agentPhone,
      if (!editing) 'agent_whatsapp': ?agentPhone,
      if (!editing) 'agent_email': ?agentEmail,
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
    'years': years,
    'level': level,
    'delivery': delivery,
    'title': title,
    'description': description,
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
    d.finishing = j['finishing'] as String?;
    d.delivery = j['delivery'] == null ? null : '${j['delivery']}';
    d.view = j['view'] as String?;
    d.price = '${j['price'] ?? ''}';
    d.payment = (j['payment'] as String?) ?? 'cash';
    d.down = '${j['down'] ?? ''}';
    d.years = '${j['years'] ?? ''}';
    d.title = '${j['title'] ?? ''}';
    d.description = '${j['description'] ?? ''}';
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
    d.status = s(j['property_status']) == 'for_sale' ? 'for_sale' : 'for_rent';
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
    final price = n(j['price']);
    if (price != null) d.price = _trim(price);
    final pay = (j['payment_options'] is List)
        ? (j['payment_options'] as List).map((e) => '$e').toList()
        : const <String>[];
    d.payment = pay.contains('installments') ? 'installments' : 'cash';
    d.origPayment = d.payment;
    final down = n(j['down_payment_percent']);
    if (down != null) d.down = _trim(down);
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
