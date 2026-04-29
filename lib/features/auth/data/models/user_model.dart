import '../../domain/entities/user.dart';

class UserModel extends User {
  final String? token;

  const UserModel({
    required super.id,
    super.name,
    super.email,
    super.phone,
    super.avatar,
    super.gender,
    super.dob,
    super.country,
    super.city,
    super.userType,
    super.preferredLanguage,
    super.referralCode,
    super.isProfileComplete,
    super.isActive,
    super.fcmToken,
    super.subscriptionId,
    super.createdAt,
    super.updatedAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // API wraps user data in a 'data' field for login and /auth/me
    final userData = json['data'] as Map<String, dynamic>? ?? json;
    return UserModel(
      id: userData['id'] as int? ?? 0,
      name: userData['name'] as String?,
      email: userData['email'] as String?,
      phone: userData['phone'] as String?,
      avatar: userData['profile_picture'] as String?,
      gender: userData['gender'] as String?,
      dob: _parseDate(userData['date_of_birth']),
      country: userData['country'] as String?,
      city: userData['city'] as String?,
      userType: userData['user_type'] as String?,
      preferredLanguage: userData['preferred_language'] as String?,
      referralCode: userData['referral_code'] as String?,
      isProfileComplete: userData['is_profile_complete'] as bool? ?? false,
      isActive: userData['is_active'] as bool? ?? true,
      fcmToken: userData['fcm_token'] as String?,
      subscriptionId: userData['subscription_id'] as int?,
      createdAt: _parseDate(userData['created_at']),
      updatedAt: _parseDate(userData['updated_at']),
      token: json['token'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_picture': avatar,
      'gender': gender,
      'date_of_birth': dob?.toIso8601String(),
      'country': country,
      'city': city,
      'user_type': userType,
      'preferred_language': preferredLanguage,
      'referral_code': referralCode,
      'is_profile_complete': isProfileComplete,
      'is_active': isActive,
      'fcm_token': fcmToken,
      'subscription_id': subscriptionId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'token': token,
    };
  }
}
