import '../../../core/network/api_client.dart';

String? _s(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
int _i(dynamic v) => v is num ? v.toInt() : 0;

/// What an answer was built on: listings, compounds and news the assistant read.
class AskRefs {
  final List<Map<String, dynamic>> properties;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> news;
  final List<(String label, String value)> facts;

  const AskRefs({
    this.properties = const [],
    this.projects = const [],
    this.news = const [],
    this.facts = const [],
  });
  static const none = AskRefs();

  bool get isEmpty => properties.isEmpty && projects.isEmpty && news.isEmpty;

  factory AskRefs.fromJson(dynamic j) {
    if (j is! Map) return none;
    List<Map<String, dynamic>> list(dynamic v) =>
        v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];
    return AskRefs(
      properties: list(j['properties']),
      projects: list(j['projects']),
      news: list(j['news']),
      facts: [
        for (final f in list(j['facts']))
          if (_s(f['label']) != null && _s(f['value']) != null)
            (_s(f['label'])!, _s(f['value'])!),
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
