import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_item_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationItemModel>> getNotifications({int page = 1, int limit = 20});
  Future<int> getUnreadCount();
  Future<void> markRead(int receiptId);
  Future<void> markAllRead();
  Future<void> registerFcmToken({
    required String token,
    required String deviceId,
    required String platform,
    Map<String, dynamic>? deviceInfo,
  });
  Future<void> unregisterFcmToken(String deviceId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;
  const NotificationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<NotificationItemModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.notifications,
        queryParams: {'page': page, 'limit': limit, 'sort': 'created_at'},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List;
      return data
          .whereType<Map<String, dynamic>>()
          .map(NotificationItemModel.fromJson)
          .toList();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await apiClient.get(ApiEndpoints.notificationsUnreadCount);
      final body = response.data as Map<String, dynamic>;
      return (body['data']['count'] as num).toInt();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> markRead(int receiptId) async {
    try {
      await apiClient.patch(ApiEndpoints.notificationRead(receiptId));
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await apiClient.patch(ApiEndpoints.notificationsReadAll);
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> registerFcmToken({
    required String token,
    required String deviceId,
    required String platform,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      await apiClient.post(
        ApiEndpoints.fcmTokens,
        data: {
          'token': token,
          'device_id': deviceId,
          'platform': platform,
          'device_info': deviceInfo,
        },
      );
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> unregisterFcmToken(String deviceId) async {
    try {
      await apiClient.delete(ApiEndpoints.fcmToken(deviceId));
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
