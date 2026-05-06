import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_subscription_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<void> createSubscription({required int packageId});
  Future<UserSubscriptionModel> getMySubscription();
  Future<void> upgradeSubscription({required int packageId});
  Future<void> cancelSubscription();
  Future<List<UserSubscriptionModel>> getSubscriptionHistory();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient apiClient;

  SubscriptionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<void> createSubscription({required int packageId}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.subscriptions,
        data: {'package_id': packageId},
      );
      if (response.statusCode == null || response.statusCode! >= 300) {
        throw ServerException();
      }
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> upgradeSubscription({required int packageId}) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.upgradeSubscription,
        data: {'package_id': packageId},
      );
      if (response.statusCode == null || response.statusCode! >= 300) {
        throw ServerException();
      }
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> cancelSubscription() async {
    try {
      final response = await apiClient.patch(ApiEndpoints.cancelSubscription);
      if (response.statusCode == null || response.statusCode! >= 300) {
        throw ServerException();
      }
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<List<UserSubscriptionModel>> getSubscriptionHistory() async {
    try {
      final response = await apiClient.get(ApiEndpoints.subscriptionHistory);
      if (response.statusCode == 200) {
        final list = response.data['data'] as List<dynamic>;
        return list
            .map((e) => UserSubscriptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<UserSubscriptionModel> getMySubscription() async {
    try {
      final response = await apiClient.get(ApiEndpoints.mySubscription);
      if (response.statusCode == 200) {
        return UserSubscriptionModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
