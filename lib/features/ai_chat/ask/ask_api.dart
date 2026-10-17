import '../../../core/network/api_client.dart';
import '../../listing/listing_api.dart' show DraftReply;
import '../../units/data/payment_plan.dart';

String? _s(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
int _i(dynamic v) => v is num ? v.toInt() : 0;

/// Something the assistant did for the person: followed a place, saved a unit (or the reverse).
class AskAction {
  final String action; // follow | unfollow | save | unsave
  final bool changed; // false = it was already that way
  final String entityType; // compound | developer | property
  final int entityId;
  final String nameAr;
  final String nameEn;
  const AskAction(
    this.action,
    this.changed,
    this.entityType,
    this.entityId,
    this.nameAr,
    this.nameEn,
  );

  static AskAction? fromJson(dynamic j) {
    if (j is! Map<String, dynamic>) return null;
    final action = _s(j['action']);
    final type = _s(j['entity_type']);
    if (action == null || type == null || _i(j['entity_id']) == 0) return null;
    return AskAction(
      action,
      j['changed'] == true,
      type,
      _i(j['entity_id']),
      _s(j['name_ar']) ?? '',
      _s(j['name_en']) ?? '',
    );
  }

  String name(bool arabic) => arabic
      ? (nameAr.isNotEmpty ? nameAr : nameEn)
      : (nameEn.isNotEmpty ? nameEn : nameAr);
}

/// A question the assistant asks before a search, with answers the person can tap.
class AskQuestion {
  final String question;
  final List<String> options;
  const AskQuestion(this.question, this.options);

  static AskQuestion? fromJson(dynamic j) {
    if (j is! Map<String, dynamic>) return null;
    final q = _s(j['question']);
    final o = (j['options'] is List ? j['options'] as List : const [])
        .whereType<String>()
        .where((x) => x.trim().isNotEmpty)
        .toList();
    if (q == null || o.length < 2) return null;
    return AskQuestion(q, o);
  }
}

/// One payment plan the assistant quoted, read from the unit's own record (so the numbers are the developer's).
class AskPlanRef {
  final Map<String, dynamic> property; // id, titles, price, first image
  final PaymentPlan plan;
  final int plansCount;
  final int? deliveryYear;
  final DateTime? publishedOn; // when the developer published these figures
  const AskPlanRef(
    this.property,
    this.plan,
    this.plansCount,
    this.deliveryYear, [
    this.publishedOn,
  ]);

  int get propertyId => _i(property['id']);

  static AskPlanRef? fromJson(dynamic j) {
    if (j is! Map<String, dynamic>) return null;
    final property = j['property'];
    final plan = j['plan'];
    if (property is! Map<String, dynamic> || plan is! Map<String, dynamic>)
      return null;
    return AskPlanRef(
      {...property, 'price': property['price']?.toString()},
      PaymentPlan.fromJson(plan),
      _i(j['plans_count']),
      property['delivery_year'] is num
          ? (property['delivery_year'] as num).toInt()
          : null,
      property['published_on'] is String
          ? DateTime.tryParse(property['published_on'] as String)
          : null,
    );
  }
}

/// What an answer was built on: listings, compounds and news the assistant read.
class AskRefs {
  final List<Map<String, dynamic>> properties;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> news;
  final List<(String label, String value)> facts;
  final List<AskPlanRef> plans;
  final List<AskAction> actions;
  final List<AskQuestion> questions;

  /// The listing checklist, when the person asked the assistant to create a listing.
  final DraftReply? listing;

  const AskRefs({
    this.properties = const [],
    this.projects = const [],
    this.news = const [],
    this.facts = const [],
    this.plans = const [],
    this.actions = const [],
    this.questions = const [],
    this.listing,
  });
  static const none = AskRefs();

  bool get isEmpty => properties.isEmpty && projects.isEmpty && news.isEmpty;

  factory AskRefs.fromJson(dynamic j) {
    if (j is! Map) return none;
    List<Map<String, dynamic>> list(dynamic v) =>
        v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];
    return AskRefs(
      listing: j['listing'] is Map
          ? DraftReply.fromJson(Map<String, dynamic>.from(j['listing'] as Map))
          : null,
      properties: list(j['properties']),
      projects: list(j['projects']),
      news: list(j['news']),
      facts: [
        for (final f in list(j['facts']))
          if (_s(f['label']) != null && _s(f['value']) != null)
            (_s(f['label'])!, _s(f['value'])!),
      ],
      plans: [
        for (final p in (j['plans'] is List ? j['plans'] as List : const []))
          if (AskPlanRef.fromJson(p) != null) AskPlanRef.fromJson(p)!,
      ],
      actions: [
        for (final a
            in (j['actions'] is List ? j['actions'] as List : const []))
          if (AskAction.fromJson(a) != null) AskAction.fromJson(a)!,
      ],
      questions: [
        for (final q
            in (j['questions'] is List ? j['questions'] as List : const []))
          if (AskQuestion.fromJson(q) != null) AskQuestion.fromJson(q)!,
      ],
    );
  }
}

class AskTurn {
  final bool user;
  final String text;
  final AskRefs refs;
  const AskTurn(this.user, this.text, [this.refs = AskRefs.none]);
}

/// One row of the history list.
class AskSessionRow {
  final int id;
  final String title;
  final DateTime updatedAt;
  final int listings;
  final int compounds;
  final int news;

  const AskSessionRow(
    this.id,
    this.title,
    this.updatedAt,
    this.listings,
    this.compounds,
    this.news,
  );

  factory AskSessionRow.fromJson(Map<String, dynamic> j) {
    final s = j['summary'] is Map ? j['summary'] as Map : const {};
    return AskSessionRow(
      _i(j['id']),
      _s(j['title']) ?? '—',
      DateTime.tryParse(_s(j['updated_at']) ?? '')?.toLocal() ?? DateTime.now(),
      _i(s['properties']),
      _i(s['projects']),
      _i(s['news']),
    );
  }
}

class AskReply {
  final String text;
  final AskRefs refs;
  const AskReply(this.text, this.refs);
}

/// The whole-market assistant: sessions, messages, history.
class AskApi {
  final ApiClient client;
  AskApi(this.client);

  Map<String, dynamic> _lang(String lang) => {'Accept-Language': lang};

  Future<List<AskSessionRow>> sessions() async {
    final res = await client.get('/chat/sessions', queryParams: {'limit': 50});
    final d = res.data['data'];
    return [
      for (final m
          in (d is List ? d : const []).whereType<Map<String, dynamic>>())
        AskSessionRow.fromJson(m),
    ];
  }

  Future<List<AskTurn>> messages(int sessionId) async {
    final res = await client.get(
      '/chat/sessions/$sessionId/messages',
      queryParams: {'limit': 100, 'order': 'ASC'},
    );
    final d = res.data['data'];
    return [
      for (final m
          in (d is List ? d : const []).whereType<Map<String, dynamic>>())
        if (m['role'] == 'user' || m['role'] == 'assistant')
          AskTurn(
            m['role'] == 'user',
            _s(m['content']) ?? '',
            m['role'] == 'assistant'
                ? AskRefs.fromJson(m['references'])
                : AskRefs.none,
          ),
    ];
  }

  Future<int> createSession(String title, String lang) async {
    final res = await client.post(
      '/chat/sessions',
      data: {'title': title},
      headers: _lang(lang),
    );
    return _i(res.data['data']['id']);
  }

  Future<AskReply> send(
    int sessionId,
    String text,
    String lang, {
    int? voiceId,
  }) async {
    final res = await client.post(
      '/chat/sessions/$sessionId/messages',
      data: {'content': text, 'voice_id': ?voiceId},
      headers: _lang(lang),
    );
    final d = res.data['data'] as Map<String, dynamic>;
    return AskReply(_s(d['reply']) ?? '', AskRefs.fromJson(d['references']));
  }

  Future<void> delete(int sessionId) =>
      client.delete('/chat/sessions/$sessionId');
}
