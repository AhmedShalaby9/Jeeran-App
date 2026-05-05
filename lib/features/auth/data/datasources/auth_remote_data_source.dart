import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String phone, {String? fcmToken});
  Future<UserModel> completeProfile(CompleteProfileParams params);
  Future<UserModel> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login(String phone, {String? fcmToken}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {
          'phone': phone,
          if (fcmToken != null) 'fcm_token': fcmToken,
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
