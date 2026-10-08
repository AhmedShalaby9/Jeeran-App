import '../../core/network/api_client.dart';

String? _s(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
int _i(dynamic v) => v is num ? v.toInt() : 0;

class SellerRequestInfo {
  final String status; // pending | approved | rejected
  final String? reason;
  final DateTime? createdAt;
  const SellerRequestInfo(this.status, this.reason, this.createdAt);
}

class PlanInfo {
  final String nameAr;
  final String nameEn;
  final bool isFree;
  final int used;
  final int total;
  final DateTime? endsAt;
  const PlanInfo(
    this.nameAr,
    this.nameEn,
    this.isFree,
    this.used,
    this.total,
    this.endsAt,
  );

  int get left => (total - used).clamp(0, total);

  /// Three or fewer left: the card nudges towards Upgrade.
  bool get low => left <= 3;
  String name(bool ar) => ar
      ? (nameAr.isNotEmpty ? nameAr : nameEn)
      : (nameEn.isNotEmpty ? nameEn : nameAr);
}

/// What the You tab shows, from `GET /me/summary`.
class YouSummary {
  final String name;
  final String? email;
  final String? phone;
  final String userType; // buyer | seller | admin | super_admin
  final String? picture;
  final SellerRequestInfo? request;
  final PlanInfo? plan;
  final int live;
  final int inReview;
  final int adsCount;
  final int unread;
  final int received30d;
  final int placesFollowed;

  const YouSummary({
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.picture,
    required this.request,
    required this.plan,
    required this.live,
    required this.inReview,
    required this.adsCount,
    required this.unread,
    required this.received30d,
    required this.placesFollowed,
  });

  bool get isSeller => userType == 'seller';
  bool get isAdmin => userType == 'admin' || userType == 'super_admin';

  factory YouSummary.fromJson(Map<String, dynamic> j) {
    final u = j['user'] is Map<String, dynamic>
        ? j['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final r = j['seller_request'] is Map<String, dynamic>
        ? j['seller_request'] as Map<String, dynamic>
        : null;
    final p = j['plan'] is Map<String, dynamic>
        ? j['plan'] as Map<String, dynamic>
        : null;
    final l = j['listings'] is Map<String, dynamic>
        ? j['listings'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final a = j['ai_ads'] is Map<String, dynamic>
        ? j['ai_ads'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final n = j['notifications'] is Map<String, dynamic>
        ? j['notifications'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return YouSummary(
      name: _s(u['name']) ?? '',
      email: _s(u['email']),
      phone: _s(u['phone']),
      userType: _s(u['user_type']) ?? 'buyer',
      picture: _s(u['profile_picture']),
      request: r == null
          ? null
          : SellerRequestInfo(
              _s(r['status']) ?? 'pending',
              _s(r['rejection_reason']),
              DateTime.tryParse(_s(r['created_at']) ?? '')?.toLocal(),
            ),
      plan: p == null
          ? null
          : PlanInfo(
              _s(p['name_ar']) ?? '',
              _s(p['name_en']) ?? '',
              p['is_free'] == true,
              _i(p['used']),
              _i(p['total']),
              DateTime.tryParse(_s(p['end_date']) ?? ''),
            ),
      live: _i(l['live']),
      inReview: _i(l['in_review']),
      adsCount: _i(a['count']),
      unread: _i(n['unread']),
      received30d: _i(n['received_30d']),
      placesFollowed: _i(n['places_followed']),
    );
  }
}

class YouApi {
  final ApiClient client;
  YouApi(this.client);

  Future<YouSummary> summary() async {
    final res = await client.get('/me/summary');
    return YouSummary.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
