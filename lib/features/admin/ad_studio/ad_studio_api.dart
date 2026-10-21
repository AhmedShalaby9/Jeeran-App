import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

String _s(dynamic v) => v is String ? v : '';
String? _n(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

/// What the AI understood from the brief (every line can be corrected before it writes).
class AdUnderstood {
  String? audience, angle, feel, mustShow;
  AdUnderstood({this.audience, this.angle, this.feel, this.mustShow});

  factory AdUnderstood.fromJson(Map<String, dynamic>? j) => AdUnderstood(
    audience: _n(j?['audience']),
    angle: _n(j?['angle']),
    feel: _n(j?['feel']),
    mustShow: _n(j?['must_show']),
  );

  Map<String, dynamic> toJson() => {'audience': audience, 'angle': angle, 'feel': feel, 'must_show': mustShow};
}

/// One fact the ad may quote, with where it came from. Computed on the server from live data.
class AdFact {
  final String key, labelEn, labelAr, detailEn, detailAr, source;
  final bool defaultOn;
  final List<num> numbers; // every number the fact contains: what the ad's copy may repeat
  const AdFact({required this.key, required this.labelEn, required this.labelAr, this.detailEn = '', this.detailAr = '', this.source = '', this.defaultOn = false, this.numbers = const []});

  factory AdFact.fromJson(Map<String, dynamic> j) => AdFact(
    key: _s(j['key']),
    labelEn: _s(j['label_en']),
    labelAr: _s(j['label_ar']),
    detailEn: _s(j['detail_en']),
    detailAr: _s(j['detail_ar']),
    source: _s(j['source']),
    defaultOn: j['default_on'] == true,
    numbers: [for (final n in (j['numbers'] is List ? j['numbers'] as List : const [])) if (n is num) n],
  );

  Map<String, dynamic> toJson() => {'key': key, 'label_en': labelEn, 'label_ar': labelAr, 'detail_en': detailEn, 'detail_ar': detailAr, 'source': source, 'numbers': numbers};

  String label(bool ar) => ar && labelAr.isNotEmpty ? labelAr : labelEn;
  String detail(bool ar) => ar && detailAr.isNotEmpty ? detailAr : detailEn;
}

class AdBriefResult {
  final AdUnderstood understood;
  final List<AdFact> facts;
  final List<String> images; // the compound's own photos
  final String subjectEn, subjectAr;
  final int? sponsorId;
  final String? sponsorName;
  final String targetType;
  final int? targetId;
  const AdBriefResult({required this.understood, required this.facts, required this.images, this.subjectEn = '', this.subjectAr = '', this.sponsorId, this.sponsorName, this.targetType = 'none', this.targetId});

  factory AdBriefResult.fromJson(Map<String, dynamic> j) {
    final sponsor = j['sponsor'] is Map ? Map<String, dynamic>.from(j['sponsor'] as Map) : const <String, dynamic>{};
    final target = j['target'] is Map ? Map<String, dynamic>.from(j['target'] as Map) : const <String, dynamic>{};
    final subject = j['subject'] is Map ? Map<String, dynamic>.from(j['subject'] as Map) : const <String, dynamic>{};
    return AdBriefResult(
      understood: AdUnderstood.fromJson(j['understood'] is Map ? Map<String, dynamic>.from(j['understood'] as Map) : null),
      facts: [for (final f in (j['facts'] is List ? j['facts'] as List : const []).whereType<Map>()) AdFact.fromJson(Map<String, dynamic>.from(f))],
      images: [for (final u in (j['images'] is List ? j['images'] as List : const [])) if (u is String) u],
      subjectEn: _s(subject['en']),
      subjectAr: _s(subject['ar']),
      sponsorId: sponsor['id'] is num ? (sponsor['id'] as num).toInt() : null,
      sponsorName: _n(sponsor['name']),
      targetType: _s(target['type']).isEmpty ? 'none' : _s(target['type']),
      targetId: target['id'] is num ? (target['id'] as num).toInt() : null,
    );
  }
}

/// One of the three ads the AI wrote.
class AdVariation {
  final String id, tone;
  final String headEn, subEn, ctaEn, headAr, subAr, ctaAr;
  final String? imageUrl;
  final bool aiImage; // the photo was made by the image model from the admin's photos (buyers see an "AI image" mark)
  final List<AdFact> facts; // the facts this copy really quotes
  final bool fallback; // plain copy built from the facts (the AI's own text was rejected)
  const AdVariation({required this.id, required this.tone, this.headEn = '', this.subEn = '', this.ctaEn = '', this.headAr = '', this.subAr = '', this.ctaAr = '', this.imageUrl, this.aiImage = false, this.facts = const [], this.fallback = false});

  factory AdVariation.fromJson(Map<String, dynamic> j) => AdVariation(
    id: _s(j['id']),
    tone: _s(j['tone']),
    headEn: _s(j['head_en']),
    subEn: _s(j['sub_en']),
    ctaEn: _s(j['cta_en']),
    headAr: _s(j['head_ar']),
    subAr: _s(j['sub_ar']),
    ctaAr: _s(j['cta_ar']),
    imageUrl: _n(j['image_url']),
    aiImage: j['ai_image'] == true,
    facts: [for (final f in (j['facts'] is List ? j['facts'] as List : const []).whereType<Map>()) AdFact.fromJson(Map<String, dynamic>.from(f))],
    fallback: j['fallback'] == true,
  );

  String head(bool ar) => ar ? (headAr.isNotEmpty ? headAr : headEn) : (headEn.isNotEmpty ? headEn : headAr);
  String sub(bool ar) => ar ? (subAr.isNotEmpty ? subAr : subEn) : (subEn.isNotEmpty ? subEn : subAr);
  String cta(bool ar) => ar ? (ctaAr.isNotEmpty ? ctaAr : ctaEn) : (ctaEn.isNotEmpty ? ctaEn : ctaAr);
}

/// A saved set of variations (a "Draft" in the studio list) and what it was made from.
class AdDraft {
  final int id;
  final String title;
  final List<AdVariation> variations;
  final int? developerId, compoundId;
  final String? sponsorName;
  final String slot, targetType;
  final int? targetId;
  final List<AdFact> facts;
  final DateTime? createdAt;
  final String subjectEn, subjectAr;
  final String imageMode;
  final String kind; // inventory | app
  final int width, height; // the pixels the ad was made at
  const AdDraft({this.width = 1200, this.height = 825, this.imageMode = 'generate', this.kind = 'inventory', required this.id, required this.title, required this.variations, this.subjectEn = '', this.subjectAr = '', this.developerId, this.compoundId, this.sponsorName, this.slot = 'explore_top', this.targetType = 'none', this.targetId, this.facts = const [], this.createdAt});

  bool get isApp => kind == 'app';

  factory AdDraft.fromJson(Map<String, dynamic> j) {
    final brief = j['brief'] is Map ? Map<String, dynamic>.from(j['brief'] as Map) : const <String, dynamic>{};
    final sponsor = brief['sponsor'] is Map ? Map<String, dynamic>.from(brief['sponsor'] as Map) : const <String, dynamic>{};
    final target = brief['target'] is Map ? Map<String, dynamic>.from(brief['target'] as Map) : const <String, dynamic>{};
    int? i(dynamic v) => v is num ? v.toInt() : null;
    final subject = brief['subject'] is Map ? Map<String, dynamic>.from(brief['subject'] as Map) : const <String, dynamic>{};
    return AdDraft(
      subjectEn: _s(subject['en']),
      subjectAr: _s(subject['ar']),
      imageMode: _s(brief['image_mode']).isEmpty ? 'generate' : _s(brief['image_mode']),
      kind: _s(brief['kind']).isEmpty ? 'inventory' : _s(brief['kind']),
      width: i(brief['width']) ?? 1200,
      height: i(brief['height']) ?? 825,
      id: i(j['id']) ?? 0,
      title: _s(j['title']),
      variations: [for (final v in (j['variations'] is List ? j['variations'] as List : const []).whereType<Map>()) AdVariation.fromJson(Map<String, dynamic>.from(v))],
      developerId: i(sponsor['id']),
      compoundId: i(brief['compound_id']),
      sponsorName: _n(sponsor['name']),
      slot: _s(brief['slot']).isEmpty ? 'explore_top' : _s(brief['slot']),
      targetType: _s(target['type']).isEmpty ? 'none' : _s(target['type']),
      targetId: i(target['id']),
      facts: [for (final f in (j['facts'] is List ? j['facts'] as List : const []).whereType<Map>()) AdFact.fromJson(Map<String, dynamic>.from(f))],
      createdAt: DateTime.tryParse(_s(j['created_at']))?.toLocal(),
    );
  }
}

/// The sizes an ad can be made at: id, label key, width × height, and where it shows.
const adSizes = <(String, String, int, int)>[
  ('top', 'adstudio.size_top', 1200, 825),
  ('feed', 'adstudio.size_feed', 1200, 600),
  ('profile', 'adstudio.size_profile', 1080, 1080),
  ('story', 'adstudio.size_story', 1080, 1920),
  ('post', 'adstudio.size_post', 1080, 1350),
  ('custom', 'adstudio.size_custom', 0, 0),
];

/// What the admin typed and picked on the brief screen.
class AdBrief {
  String summary;
  String kind; // inventory (a place) | app (the Jeeran app itself — never linked to a compound/developer/unit)
  int? developerId, compoundId, propertyId;
  String? developerName, compoundName, propertyName;
  String slot, tone, language;
  String imageMode; // original | generate
  String size; // top | feed | profile | story | post | custom
  int customWidth, customHeight;
  List<String> images; // uploaded by the admin (public URLs)
  AdBrief({this.summary = '', this.kind = 'inventory', this.developerId, this.compoundId, this.propertyId, this.developerName, this.compoundName, this.propertyName, this.slot = 'explore_top', this.tone = 'Premium', this.language = 'English + Arabic', this.imageMode = 'generate', this.size = 'top', this.customWidth = 1080, this.customHeight = 1350, List<String>? images}) : images = images ?? [];

  bool get isApp => kind == 'app';

  /// The pixels the ad is made at.
  (int, int) get pixels {
    if (size == 'custom') return (customWidth, customHeight);
    final s = adSizes.firstWhere((x) => x.$1 == size, orElse: () => adSizes.first);
    return (s.$3, s.$4);
  }

  Map<String, dynamic> toJson() => {
    'summary': summary.trim(),
    'kind': kind,
    'developer_id': isApp ? null : developerId,
    'compound_id': isApp ? null : compoundId,
    'property_id': isApp ? null : propertyId,
    'slot': slot,
    'tone': tone,
    'language': language,
    'image_mode': imageMode,
    'size': size,
    if (size == 'custom') 'width': customWidth,
    if (size == 'custom') 'height': customHeight,
  };
}

/// How an uploaded image scored: ok, or a warning (blurry / off-brief: skipped unless kept) or bad (too small: not used).
class AdImageScore {
  final String url, status, label; // status: ok | warn | bad
  const AdImageScore({required this.url, required this.status, required this.label});

  factory AdImageScore.fromJson(Map<String, dynamic> j) => AdImageScore(url: _s(j['url']), status: _s(j['status']).isEmpty ? 'ok' : _s(j['status']), label: _s(j['label']).isEmpty ? 'good' : _s(j['label']));

  bool get ok => status == 'ok';
  bool get bad => status == 'bad';
}

/// The Ad studio's server calls. Tests pass a fake.
class AdStudioApi {
  ApiClient get _c => sl<ApiClient>();

  Future<AdBriefResult> brief(AdBrief b) async {
    final res = await _c.postLong('/ad-studio/brief', data: b.toJson());
    return AdBriefResult.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
  }

  Future<AdDraft> generate(AdBrief b, {required AdUnderstood understood, required List<String> approved}) async {
    final res = await _c.postLong('/ad-studio/generate', data: {...b.toJson(), 'understood': understood.toJson(), 'approved': approved, 'images': b.images});
    return AdDraft.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
  }

  Future<List<AdDraft>> drafts() async {
    final res = await _c.get('/ad-studio/drafts');
    final d = res.data['data'];
    return [for (final m in (d is List ? d : const []).whereType<Map>()) AdDraft.fromJson(Map<String, dynamic>.from(m))];
  }

  Future<AdDraft> draft(int id) async {
    final res = await _c.get('/ad-studio/drafts/$id');
    return AdDraft.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
  }

  /// "Shorter headline" / "More urgent" / "Different photo" on one variation. `changed` false: nothing better was found.
  Future<(AdDraft, bool)> refine(int draftId, String variationId, String action) async {
    final res = await _c.postLong('/ad-studio/drafts/$draftId/refine', data: {'variation_id': variationId, 'action': action});
    return (AdDraft.fromJson(Map<String, dynamic>.from(res.data['data'] as Map)), res.data['changed'] != false);
  }

  /// Three new variations from the same brief and approved facts.
  Future<AdDraft> regenerate(int draftId) async {
    final res = await _c.postLong('/ad-studio/drafts/$draftId/regenerate', data: const {});
    return AdDraft.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
  }

  Future<void> discard(int id) async {
    await _c.delete('/ad-studio/drafts/$id');
  }

  Future<List<AdImageScore>> scoreImages(List<String> urls, {required AdBrief brief}) async {
    final res = await _c.postLong('/ad-studio/images/score', data: {'urls': urls, 'summary': brief.summary, ...brief.toJson()..remove('summary')});
    final d = res.data['data'];
    return [for (final m in (d is List ? d : const []).whereType<Map>()) AdImageScore.fromJson(Map<String, dynamic>.from(m))];
  }

  /// Uploads one picked image and returns its public URL.
  Future<String> upload(String path) async {
    final res = await _c.postMultipart(ApiEndpoints.uploadSingle, filePath: path, queryParams: {'folder': 'banners'});
    final body = res.data;
    final data = body is Map ? body['data'] : null;
    final url = data is String ? data : (data is Map ? data['url'] : (body is Map ? body['url'] : null));
    if (url is! String || url.isEmpty) throw Exception('upload failed');
    return url;
  }
}
