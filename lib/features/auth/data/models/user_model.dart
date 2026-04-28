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
      dob: DateTime.tryParse(userData['date_of_birth'] as String? ?? ''),
      country: userData['country'] as String?,
      city: userData['city'] as String?,
      userType: userData['user_type'] as String?,
      preferredLanguage: userData['preferred_language'] as String?,
      referralCode: userData['referral_code'] as String?,
      isProfileComplete: userData['is_profile_complete'] as bool? ?? false,
      isActive: userData['is_active'] as bool? ?? true,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'gender': gender,
      'date_of_birth': dob?.toIso8601String(),
      'country': country,
      'city': city,
      'user_type': userType,
      'preferred_language': preferredLanguage,
      'referral_code': referralCode,
      'is_profile_complete': isProfileComplete,
      'is_active': isActive,
      'token': token,
    };
  }
}
