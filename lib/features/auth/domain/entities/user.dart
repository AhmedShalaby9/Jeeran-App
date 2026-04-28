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
  });

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
  ];
}
