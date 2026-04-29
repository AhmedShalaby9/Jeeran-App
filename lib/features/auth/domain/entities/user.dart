import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? gender;
  final DateTime? dob;
  final String? country;
  final String? city;
  final String? userType;
  final String? preferredLanguage;
  final String? referralCode;
  final bool isProfileComplete;
  final bool isActive;
  final String? fcmToken;
  final int? subscriptionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.avatar,
    this.gender,
    this.dob,
    this.country,
    this.city,
    this.userType,
    this.preferredLanguage,
    this.referralCode,
    this.isProfileComplete = false,
    this.isActive = true,
    this.fcmToken,
    this.subscriptionId,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns true only when the user is a seller.
  bool get isSeller => userType == 'seller';

  /// Returns true for admin users.
  bool get isAdmin => userType == 'admin';

  /// Returns true for buyer users (or any non-seller, non-admin).
  bool get isBuyer => !isSeller && !isAdmin;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    avatar,
    gender,
    dob,
    country,
    city,
    userType,
    preferredLanguage,
    referralCode,
    isProfileComplete,
    isActive,
    fcmToken,
    subscriptionId,
    createdAt,
    updatedAt,
  ];
}
