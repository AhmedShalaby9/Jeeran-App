import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_item.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationItem>>> getNotifications({
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, int>> getUnreadCount();
  Future<Either<Failure, Unit>> markRead(int receiptId);
  Future<Either<Failure, Unit>> markAllRead();
  Future<Either<Failure, Unit>> registerFcmToken({
    required String token,
    required String deviceId,
    required String platform,
    Map<String, dynamic>? deviceInfo,
  });
  Future<Either<Failure, Unit>> unregisterFcmToken(String deviceId);
}
