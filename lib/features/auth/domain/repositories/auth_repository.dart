import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String phone, {String? fcmToken, String? platform, String? deviceId});
  Future<Either<Failure, bool>> sendOtp(String phone);
  Future<Either<Failure, User>> verifyOtp(String phone, String otp, {String? fcmToken, String? platform, String? deviceId});
  Future<Either<Failure, User>> firebaseVerify(String idToken, {String? fcmToken, String? platform, String? deviceId});
  Future<Either<Failure, String>> sendOtpRest(String phone, String recaptchaToken);
  Future<Either<Failure, User>> verifyOtpRest(String sessionInfo, String code, {String? fcmToken, String? platform, String? deviceId});
  Future<Either<Failure, User>> completeProfile(CompleteProfileParams params);
  Future<Either<Failure, User>> getMe();
}

class CompleteProfileParams {
  final String name;
  final String email;
  final String? gender;
  final DateTime? dob;
  final String? preferredLanguage;
  final String? country;
  final String? city;
  final String? referralCode;

  const CompleteProfileParams({
    required this.name,
    required this.email,
    this.gender,
    this.dob,
    this.preferredLanguage,
    this.country,
    this.city,
    this.referralCode,
  });
}
