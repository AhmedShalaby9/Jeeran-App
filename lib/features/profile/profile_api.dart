import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../properties/domain/repositories/property_repository.dart';

String? _s(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

/// A person's profile as other people see it, from `GET /me/profile`.
class ProfileData {
  final String name;
  final String? email, phone, picture, city, language, company, bio;
  final String userType; // buyer | seller | admin | super_admin
  final bool sellerVerified;
  final DateTime? since;
  final int? liveListings;

  const ProfileData({
    required this.name,
    required this.userType,
    this.email,
    this.phone,
    this.picture,
    this.city,
    this.language,
    this.company,
    this.bio,
    this.sellerVerified = false,
    this.since,
    this.liveListings,
  });

  /// Customers browse, buy and list; they can add a company and a bio to their profile.
  bool get isCustomer => userType != 'admin' && userType != 'super_admin';

  factory ProfileData.fromJson(Map<String, dynamic> j) => ProfileData(
    name: _s(j['name']) ?? '',
    userType: _s(j['user_type']) ?? 'customer',
    email: _s(j['email']),
    phone: _s(j['phone']),
    picture: _s(j['profile_picture']),
    city: _s(j['city']),
    language: _s(j['preferred_language']),
    company: _s(j['company_name']),
    bio: _s(j['bio']),
    sellerVerified: j['seller_verified'] == true,
    since: DateTime.tryParse(_s(j['member_since']) ?? '')?.toLocal(),
    liveListings: (j['live_listings'] as num?)?.toInt(),
  );
}

class ProfileApi {
  final ApiClient client;
  ProfileApi(this.client);

  Future<ProfileData> load() async {
    final res = await client.get('/me/profile');
    return ProfileData.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ProfileData> save(Map<String, dynamic> body) async {
    final res = await client.putWithHeaders('/me/profile', data: body);
    return ProfileData.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Uploads a new photo and returns its public URL.
  Future<String> upload(String path) async {
    final r = await sl<PropertyRepository>().uploadImage(path);
    return r.fold((_) => throw Exception('upload failed'), (u) => u);
  }
}
