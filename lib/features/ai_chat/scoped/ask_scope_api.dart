import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../ask/ask_api.dart';

enum AskScopeType { developer, compound, property }

/// The record an AI conversation is bound to.
class AskScope {
  final AskScopeType type;
  final int id;
  final String name; // shown in the header and the "Asking about X only" pill
  const AskScope(this.type, this.id, this.name);
}

class AskLimit {
  final int limit;
  final int remaining;
  const AskLimit(this.limit, this.remaining);
}

/// What the sheet shows before the first question.
class ScopeInfo {
  final String name;
  final String source; // "142 units · 4 phases · prices live today"
  final List<String> prompts;
  final AskLimit? limit;
  const ScopeInfo(this.name, this.source, this.prompts, this.limit);

  factory ScopeInfo.fromJson(Map<String, dynamic> j) => ScopeInfo(
    j['name'] as String? ?? '',
    j['source'] as String? ?? '',
    (j['prompts'] is List ? j['prompts'] as List : const [])
        .whereType<String>()
        .toList(),
    _limit(j['limit']),
  );
}

class ScopedReply {
  final String reply;
  final AskRefs
  refs; // the cards the answer rests on: units, plans, compounds, facts…
  final AskLimit? limit;
  const ScopedReply(this.reply, this.refs, this.limit);

  List<(String label, String value)> get facts => refs.facts;
}

AskLimit? _limit(dynamic v) => v is Map<String, dynamic>
    ? AskLimit(
        (v['limit'] as num?)?.toInt() ?? 0,
        (v['remaining'] as num?)?.toInt() ?? 0,
      )
    : null;

/// Calls for the "Ask about this …" sheet. Sessions are created on the first question, so opening
/// the sheet and closing it again leaves nothing behind in the user's history.
class AskScopeApi {
  final ApiClient client;
  AskScopeApi(this.client);

  Map<String, dynamic> _lang(String lang) => {'Accept-Language': lang};

  Future<ScopeInfo> info(AskScope scope, String lang) async {
    final res = await client.get(
      ApiEndpoints.chatScope,
      queryParams: {'type': scope.type.name, 'id': scope.id},
      headers: _lang(lang),
    );
    return ScopeInfo.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Creates a chat; with a [scope] it is bound to that record, without one it is market-wide.
  Future<int> createSession(AskScope? scope, String lang) async {
    final res = await client.post(
      ApiEndpoints.chatSessions,
      data: {
        if (scope != null) 'scope_type': scope.type.name,
        if (scope != null) 'scope_id': scope.id,
      },
      headers: _lang(lang),
    );
    return (res.data['data']['id'] as num).toInt();
  }

  Future<ScopedReply> send(
    int sessionId,
    String text,
    String lang, {
    int? voiceId,
  }) async {
    final res = await client.post(
      ApiEndpoints.chatMessages(sessionId),
      data: {'content': text, 'voice_id': ?voiceId},
      headers: _lang(lang),
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return ScopedReply(
      data['reply'] as String? ?? '',
      AskRefs.fromJson(data['references']),
      _limit(data['limit']),
    );
  }

  Future<void> widen(int sessionId) =>
      client.patch(ApiEndpoints.chatSessionScope(sessionId));
}
