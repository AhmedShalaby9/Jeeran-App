import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_subscription_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<void> createSubscription({required int packageId});
  Future<UserSubscriptionModel> getMySubscription();
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
