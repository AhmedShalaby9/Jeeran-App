// ignore_for_file: use_null_aware_elements
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String phone, {String? fcmToken, String? platform, String? deviceId});
  Future<bool> sendOtp(String phone);
  Future<UserModel> verifyOtp(String phone, String otp, {String? fcmToken, String? platform, String? deviceId});
  Future<UserModel> firebaseVerify(String idToken, {String? fcmToken, String? platform, String? deviceId});
  Future<String> sendOtpRest(String phone, String recaptchaToken);
  Future<UserModel> verifyOtpRest(String sessionInfo, String code, {String? fcmToken, String? platform, String? deviceId});
  Future<UserModel> completeProfile(CompleteProfileParams params);
  Future<UserModel> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login(String phone, {String? fcmToken, String? platform, String? deviceId}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: <String, dynamic>{
          'phone': phone,
          if (fcmToken != null) 'fcm_token': fcmToken,
          if (platform != null) 'platform': platform,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<bool> sendOtp(String phone) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.sendOtp,
        data: {'phone': phone},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data['is_new_user'] as bool?) ?? false;
      }
      throw ServerException(response.data?['message'] as String? ?? '');
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> verifyOtp(String phone, String otp, {String? fcmToken, String? platform, String? deviceId}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.verifyOtp,
        data: <String, dynamic>{
          'phone': phone,
          'otp': otp,
          if (fcmToken != null) 'fcm_token': fcmToken,
          if (platform != null) 'platform': platform,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(response.data?['message'] as String? ?? '');
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> firebaseVerify(String idToken, {String? fcmToken, String? platform, String? deviceId}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.firebaseVerify,
        data: <String, dynamic>{
          'id_token': idToken,
          if (fcmToken != null) 'fcm_token': fcmToken,
          if (platform != null) 'platform': platform,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(response.data?['message'] as String? ?? '');
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<String> sendOtpRest(String phone, String recaptchaToken) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.sendOtpRest,
        data: {'phone': phone, 'recaptcha_token': recaptchaToken},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['session_info'] as String;
      }
      throw ServerException(response.data?['message'] as String? ?? '');
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> verifyOtpRest(String sessionInfo, String code, {String? fcmToken, String? platform, String? deviceId}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.verifyOtpRest,
        data: <String, dynamic>{
          'session_info': sessionInfo,
          'code': code,
          if (fcmToken != null) 'fcm_token': fcmToken,
          if (platform != null) 'platform': platform,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException(response.data?['message'] as String? ?? '');
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> completeProfile(CompleteProfileParams params) async {
    try {
      final response = await apiClient.put(
        ApiEndpoints.completeProfile,
        data: {
          'name': params.name,
          'email': params.email,
          if (params.gender != null) 'gender': params.gender,
          if (params.dob != null) 'date_of_birth': params.dob!.toIso8601String(),
          if (params.preferredLanguage != null) 'preferred_language': params.preferredLanguage,
          if (params.country != null) 'country': params.country,
          if (params.city != null) 'city': params.city,
          if (params.referralCode != null) 'referral_code': params.referralCode,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await apiClient.get(ApiEndpoints.me);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
