import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../properties/domain/repositories/property_repository.dart';
import 'listing_draft.dart';

/// What the assistant understood from one message.
class DraftReply {
  final Map<String, dynamic> draft;
  final CompoundRef? compound;
  final bool unknownCompound;
  final List<dynamic> filled;
  final List<String> missing;
  final bool complete;
  final String? question;
  final List<String> replies;
  const DraftReply({
    required this.draft,
    required this.compound,
    required this.unknownCompound,
    required this.filled,
    required this.missing,
    required this.complete,
    required this.question,
    required this.replies,
  });

  factory DraftReply.fromJson(Map<String, dynamic> j) => DraftReply(
    draft: Map<String, dynamic>.from(j['draft'] as Map? ?? {}),
    compound: j['compound'] is Map
        ? CompoundRef.fromJson(Map<String, dynamic>.from(j['compound'] as Map))
        : null,
    unknownCompound: j['unknown_compound'] == true,
    filled: (j['filled'] as List?) ?? const [],
    missing: ((j['missing'] as List?) ?? const []).map((e) => '$e').toList(),
    complete: j['complete'] == true,
    question: j['question'] as String?,
    replies: ((j['replies'] as List?) ?? const []).map((e) => '$e').toList(),
  );
}

/// What similar live units ask. [count] 0 = nothing to compare with.
class PriceBand {
  final int count;
  final double? min, p25, median, p75, max;
  const PriceBand(
    this.count,
    this.min,
    this.p25,
    this.median,
    this.p75,
    this.max,
  );

  factory PriceBand.fromJson(Map<String, dynamic> j) {
    double? d(dynamic v) => v is num ? v.toDouble() : null;
    return PriceBand(
      (j['count'] as num?)?.toInt() ?? 0,
      d(j['min']),
      d(j['p25']),
      d(j['median']),
      d(j['p75']),
      d(j['max']),
    );
  }
}

/// One of the seller's live listings, as the price shortcut names it.
class ListingBrief {
  final int id;
  final String title;
  final String? compound;
  final double? price;
  const ListingBrief(this.id, this.title, this.compound, this.price);

  factory ListingBrief.fromJson(Map<String, dynamic> j) => ListingBrief(
    (j['id'] as num).toInt(),
    '${j['title'] ?? ''}',
    j['compound'] as String?,
    (j['price'] as num?)?.toDouble(),
  );

  String get label => [
    if (title.isNotEmpty) title,
    if (compound != null) compound!,
  ].join(' · ');
}

/// What the assistant understood of "change the price of …": a proposal, or one question.
class PriceReply {
  final ListingBrief? listing;
  final double? oldPrice, newPrice, changePercent;
  final int savers;
  final String? question;
  final List<ListingBrief> candidates;
  const PriceReply({
    this.listing,
    this.oldPrice,
    this.newPrice,
    this.changePercent,
    this.savers = 0,
    this.question,
    this.candidates = const [],
  });

  bool get hasProposal => listing != null && newPrice != null;

  factory PriceReply.fromJson(Map<String, dynamic> j) {
    double? d(dynamic v) => v is num ? v.toDouble() : null;
    return PriceReply(
      listing: j['listing'] is Map
          ? ListingBrief.fromJson(
              Map<String, dynamic>.from(j['listing'] as Map),
            )
          : null,
      oldPrice: d(j['old_price']),
      newPrice: d(j['new_price']),
      changePercent: d(j['change_percent']),
      savers: (j['savers'] as num?)?.toInt() ?? 0,
      question: j['question'] as String?,
      candidates: [
        for (final c in (j['candidates'] as List?) ?? const [])
          if (c is Map) ListingBrief.fromJson(Map<String, dynamic>.from(c)),
      ],
    );
  }
}

class ListingApi {
  final ApiClient client;
  ListingApi(this.client);

  Map<String, dynamic> _lang(String lang) => {
    ...ApiClient.apiV2,
    'Accept-Language': lang,
  };

  Future<DraftReply> parse(String text, ListingDraft draft, String lang) async {
    final res = await client.post(
      '/listing-draft/parse',
      data: {'text': text, 'draft': draft.toParserJson()},
      headers: _lang(lang),
    );
    return DraftReply.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<PriceReply> priceChange(
    String text,
    String lang, {
    int? listingId,
  }) async {
    final res = await client.post(
      '/listing-draft/price-change',
      data: {'text': text, 'listing_id': ?listingId},
      headers: _lang(lang),
    );
    return PriceReply.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<({String title, String description})> describe(
    ListingDraft draft,
    String lang,
  ) async {
    final res = await client.post(
      '/listing-draft/describe',
      data: {'draft': draft.toParserJson(), 'lang': lang},
      headers: _lang(lang),
    );
    final d = res.data['data'] as Map<String, dynamic>;
    return (
      title: '${d['title'] ?? ''}',
      description: '${d['description'] ?? ''}',
    );
  }

  Future<PriceBand> priceBand(ListingDraft draft) async {
    final res = await client.get(
      '/properties/price-band',
      queryParams: {
        'compound_id': draft.compound!.id,
        'type': ?draft.type,
        'status': draft.status,
        if (!draft.noRooms) 'bedrooms': draft.bedrooms,
      },
      headers: ApiClient.apiV2,
    );
    return PriceBand.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<CompoundRef>> compounds() async {
    final res = await client.get(
      '/compounds',
      queryParams: {'limit': 200},
      headers: ApiClient.apiV2,
    );
    final d = res.data['data'];
    return [
      for (final m
          in (d is List ? d : const []).whereType<Map<String, dynamic>>())
        CompoundRef.fromJson(m),
    ];
  }

  /// Uploads a photo / video / plan and returns its public URL.
  Future<String> upload(String path) async {
    final r = await sl<PropertyRepository>().uploadImage(path);
    return r.fold((_) => throw Exception('upload failed'), (u) => u);
  }

  Future<void> create(Map<String, dynamic> body) async {
    await client.post('/properties', data: body, headers: ApiClient.apiV2);
  }

  /// The listing to edit, as the property page reads it.
  Future<Map<String, dynamic>> property(int id) async {
    final res = await client.get('/properties/$id', headers: ApiClient.apiV2);
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }

  /// Saves an edit; true when the change put the listing back in review.
  Future<bool> update(int id, Map<String, dynamic> body) async {
    final res = await client.putWithHeaders(
      '/properties/$id',
      data: body,
      headers: ApiClient.apiV2,
    );
    return res.data['in_review'] == true;
  }

  /// A free cover made from the seller's own (already uploaded) photos. Returns its URL.
  Future<String> cover(List<String> sources) async {
    final res = await client.postLong(
      '/listing-covers',
      data: {'source_images': sources},
      headers: ApiClient.apiV2,
    );
    return '${(res.data['data'] as Map)['url']}';
  }
}
