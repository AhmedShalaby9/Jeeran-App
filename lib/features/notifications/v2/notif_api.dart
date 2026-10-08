import '../../../core/network/api_client.dart';

String? _s(dynamic v) => v is String && v.isNotEmpty ? v : null;
int _i(dynamic v) => v is num ? v.toInt() : 0;

/// One row of the inbox: the receipt (read state) and the notification it points at.
class InboxItem {
  final int id; // the receipt id — what "mark read" takes
  final bool isRead;
  final DateTime createdAt;
  final String
  type; // property | project | developer | news | subscription | ad | general
  final String category;
  final String titleEn;
  final String? titleAr;
  final String bodyEn;
  final String? bodyAr;
  final int? entityId;

  const InboxItem({
    required this.id,
    required this.isRead,
    required this.createdAt,
    required this.type,
    required this.category,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.entityId,
  });

  factory InboxItem.fromJson(Map<String, dynamic> j) {
    final n = j['notification'] is Map<String, dynamic>
        ? j['notification'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return InboxItem(
      id: _i(j['id']),
      isRead: j['is_read'] == true,
      createdAt:
          DateTime.tryParse(
            _s(j['created_at']) ?? _s(n['created_at']) ?? '',
          )?.toLocal() ??
          DateTime.now(),
      type: _s(n['type']) ?? 'general',
      category: _s(n['category']) ?? 'general',
      titleEn: _s(n['title_en']) ?? '',
      titleAr: _s(n['title_ar']),
      bodyEn: _s(n['body_en']) ?? '',
      bodyAr: _s(n['body_ar']),
      entityId: n['entity_id'] is num ? (n['entity_id'] as num).toInt() : null,
    );
  }

  InboxItem asRead() => InboxItem(
    id: id,
    isRead: true,
    createdAt: createdAt,
    type: type,
    category: category,
    titleEn: titleEn,
    titleAr: titleAr,
    bodyEn: bodyEn,
    bodyAr: bodyAr,
    entityId: entityId,
  );

  String title(bool ar) =>
      ar && (titleAr ?? '').isNotEmpty ? titleAr! : titleEn;
  String body(bool ar) => ar && (bodyAr ?? '').isNotEmpty ? bodyAr! : bodyEn;
}

class InboxPage {
  final List<InboxItem> items;
  final int pages;
  const InboxPage(this.items, this.pages);
}

/// Unread totals for the header and each filter chip.
class InboxSummary {
  final int unread;
  final Map<String, int> filters; // listings | projects | plans | news | ads
  const InboxSummary(this.unread, this.filters);
  static const empty = InboxSummary(0, {});

  factory InboxSummary.fromJson(Map<String, dynamic> j) =>
      InboxSummary(_i(j['unread']), {
        for (final e
            in (j['filters'] is Map ? j['filters'] as Map : const {}).entries)
          '${e.key}': _i(e.value),
      });
}

class NotifCategory {
  final String id; // saved | plan | listing | news | ai
  final bool enabled;
  final bool locked;
  final int received30d;
  const NotifCategory(this.id, this.enabled, this.locked, this.received30d);

  NotifCategory withEnabled(bool v) =>
      NotifCategory(id, v, locked, received30d);
}

class FollowedPlace {
  final String kind; // compound | developer
  final int id;
  final String nameAr;
  final String nameEn;
  final String? image;
  final String? subtitleAr; // compound: its developer
  final String? subtitleEn;
  final bool alertsOn;
  final String? lastUpdate;
  final DateTime? lastUpdateAt;

  const FollowedPlace({
    required this.kind,
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.image,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.alertsOn,
    required this.lastUpdate,
    required this.lastUpdateAt,
  });

  factory FollowedPlace.fromJson(String kind, Map<String, dynamic> j) {
    final dev = j['developer'] is Map<String, dynamic>
        ? j['developer'] as Map<String, dynamic>
        : null;
    final up = j['last_update'] is Map<String, dynamic>
        ? j['last_update'] as Map<String, dynamic>
        : null;
    return FollowedPlace(
      kind: kind,
      id: _i(j['id']),
      nameAr: _s(j['name_ar']) ?? '',
      nameEn: _s(j['name_en']) ?? '',
      image: _s(kind == 'compound' ? j['main_image'] : j['logo']),
      subtitleAr: dev == null ? null : _s(dev['name_ar']),
      subtitleEn: dev == null ? null : _s(dev['name_en']),
      alertsOn: j['alerts_enabled'] == true,
      lastUpdate: up == null ? null : _s(up['title']),
      lastUpdateAt: up == null
          ? null
          : DateTime.tryParse(_s(up['published_at']) ?? '')?.toLocal(),
    );
  }

  FollowedPlace withAlerts(bool on) => FollowedPlace(
    kind: kind,
    id: id,
    nameAr: nameAr,
    nameEn: nameEn,
    image: image,
    subtitleAr: subtitleAr,
    subtitleEn: subtitleEn,
    alertsOn: on,
    lastUpdate: lastUpdate,
    lastUpdateAt: lastUpdateAt,
  );

  String name(bool ar) => ar
      ? (nameAr.isNotEmpty ? nameAr : nameEn)
      : (nameEn.isNotEmpty ? nameEn : nameAr);
}

class NotifSettings {
  final List<NotifCategory> categories;
  final List<FollowedPlace> compounds;
  final List<FollowedPlace> developers;
  final int received30d;

  const NotifSettings(
    this.categories,
    this.compounds,
    this.developers,
    this.received30d,
  );

  int get placesFollowed => compounds.length + developers.length;
  int get placesOn =>
      [...compounds, ...developers].where((p) => p.alertsOn).length;

  factory NotifSettings.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> list(dynamic v) =>
        v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];
    return NotifSettings(
      [
        for (final c in list(j['categories']))
          NotifCategory(
            '${c['id']}',
            c['enabled'] == true,
            c['locked'] == true,
            _i(c['received_30d']),
          ),
      ],
      [
        for (final c in list(j['compounds']))
          FollowedPlace.fromJson('compound', c),
      ],
      [
        for (final d in list(j['developers']))
          FollowedPlace.fromJson('developer', d),
      ],
      _i(j['received_30d']),
    );
  }

  NotifSettings copyWith({
    List<NotifCategory>? categories,
    List<FollowedPlace>? compounds,
    List<FollowedPlace>? developers,
  }) => NotifSettings(
    categories ?? this.categories,
    compounds ?? this.compounds,
    developers ?? this.developers,
    received30d,
  );
}

/// Everything the inbox and the notification settings talk to the API for.
class NotifApi {
  final ApiClient client;
  NotifApi(this.client);

  Map<String, dynamic> _lang(String lang) => {'Accept-Language': lang};

  Future<InboxPage> list({String? filter, int page = 1, int limit = 20}) async {
    final res = await client.get(
      '/notifications',
      queryParams: {
        'page': page,
        'limit': limit,
        if (filter != null) 'filter': filter,
      },
    );
    final data = res.data['data'];
    final pg = res.data['pagination'];
    return InboxPage([
      for (final m
          in (data is List ? data : const []).whereType<Map<String, dynamic>>())
        InboxItem.fromJson(m),
    ], pg is Map ? _i(pg['pages']) : 1);
  }

  Future<InboxSummary> summary() async {
    final res = await client.get('/notifications/summary');
    return InboxSummary.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> markRead(int receiptId) =>
      client.patch('/notifications/$receiptId/read');
  Future<void> markAllRead() => client.patch('/notifications/read-all');

  Future<NotifSettings> settings(String lang) async {
    final res = await client.get(
      '/notifications/settings',
      headers: _lang(lang),
    );
    return NotifSettings.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> setCategory(String category, bool enabled) => client.put(
    '/notifications/settings',
    data: {'category': category, 'enabled': enabled},
  );

  Future<void> setPlaceAlerts(String kind, int id, bool enabled) => client.put(
    '/user-subscriptions/alerts',
    data: {'entity_type': kind, 'entity_id': id, 'enabled': enabled},
  );

  Future<void> setAllPlaceAlerts(bool enabled) =>
      client.put('/user-subscriptions/alerts/all', data: {'enabled': enabled});
}
