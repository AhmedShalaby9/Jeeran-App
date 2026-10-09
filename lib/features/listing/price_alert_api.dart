import '../../core/network/api_client.dart';
import 'listing_draft.dart';

/// A watch on the market, as the server keeps it.
class PriceAlertDraft {
  final int? compoundId;
  final String? propertyType;
  final int? minBedrooms;
  final double? maxPrice;
  final String status; // for_sale | for_rent
  const PriceAlertDraft({
    this.compoundId,
    this.propertyType,
    this.minBedrooms,
    this.maxPrice,
    this.status = 'for_sale',
  });

  factory PriceAlertDraft.fromJson(Map<String, dynamic> j) => PriceAlertDraft(
    compoundId: (j['compound_id'] as num?)?.toInt(),
    propertyType: j['property_type'] as String?,
    minBedrooms: (j['min_bedrooms'] as num?)?.toInt(),
    maxPrice: (j['max_price'] as num?)?.toDouble(),
    status: (j['status'] as String?) ?? 'for_sale',
  );

  Map<String, dynamic> toJson() => {
    'compound_id': ?compoundId,
    'property_type': ?propertyType,
    'min_bedrooms': ?minBedrooms,
    'max_price': ?maxPrice,
    'status': status,
  };
}

/// What similar live units cost right now.
class AlertMarket {
  final int underCount;
  final double? cheapest;
  final int total;
  const AlertMarket(this.underCount, this.cheapest, this.total);

  factory AlertMarket.fromJson(dynamic j) => j is Map
      ? AlertMarket(
          (j['under_count'] as num?)?.toInt() ?? 0,
          (j['cheapest'] as num?)?.toDouble(),
          (j['total'] as num?)?.toInt() ?? 0,
        )
      : const AlertMarket(0, null, 0);
}

class AlertReply {
  final PriceAlertDraft alert;
  final CompoundRef? compound;
  final bool unknownCompound, complete;
  final AlertMarket? now;
  final String? question;
  const AlertReply({
    required this.alert,
    required this.compound,
    required this.unknownCompound,
    required this.complete,
    required this.now,
    required this.question,
  });

  factory AlertReply.fromJson(Map<String, dynamic> j) => AlertReply(
    alert: PriceAlertDraft.fromJson(
      Map<String, dynamic>.from(j['alert'] as Map),
    ),
    compound: j['compound'] is Map
        ? CompoundRef.fromJson(Map<String, dynamic>.from(j['compound'] as Map))
        : null,
    unknownCompound: j['unknown_compound'] == true,
    complete: j['complete'] == true,
    now: j['now'] == null ? null : AlertMarket.fromJson(j['now']),
    question: j['question'] as String?,
  );
}

/// An alert that is switched on.
class SavedAlert {
  final int id;
  final PriceAlertDraft alert;
  final CompoundRef? compound;
  final AlertMarket now;
  const SavedAlert(this.id, this.alert, this.compound, this.now);

  factory SavedAlert.fromJson(Map<String, dynamic> j) => SavedAlert(
    (j['id'] as num).toInt(),
    PriceAlertDraft.fromJson(j),
    j['compound'] is Map
        ? CompoundRef.fromJson(Map<String, dynamic>.from(j['compound'] as Map))
        : null,
    AlertMarket.fromJson(j['now']),
  );
}

class PriceAlertApi {
  final ApiClient client;
  PriceAlertApi(this.client);

  Map<String, dynamic> _lang(String lang) => {
    ...ApiClient.apiV2,
    'Accept-Language': lang,
  };

  Future<AlertReply> parse(
    String text,
    PriceAlertDraft? prev,
    String lang,
  ) async {
    final res = await client.post(
      '/price-alerts/parse',
      data: {'text': text, 'alert': ?prev?.toJson()},
      headers: _lang(lang),
    );
    return AlertReply.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<SavedAlert> create(PriceAlertDraft a) async {
    final res = await client.post(
      '/price-alerts',
      data: a.toJson(),
      headers: ApiClient.apiV2,
    );
    return SavedAlert.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<List<SavedAlert>> list() async {
    final res = await client.get('/price-alerts', headers: ApiClient.apiV2);
    return [
      for (final m in (res.data['data'] as List? ?? const []).whereType<Map>())
        SavedAlert.fromJson(Map<String, dynamic>.from(m)),
    ];
  }

  Future<void> remove(int id) => client.delete('/price-alerts/$id');
}
