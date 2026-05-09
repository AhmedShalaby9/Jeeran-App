import '../../domain/entities/notification_item.dart';

class NotificationDataModel extends NotificationData {
  const NotificationDataModel({
    required super.id,
    required super.titleEn,
    super.titleAr,
    required super.bodyEn,
    super.bodyAr,
    required super.type,
    super.entityId,
    required super.createdAt,
  });

  factory NotificationDataModel.fromJson(Map<String, dynamic> json) =>
      NotificationDataModel(
        id: json['id'] as int,
        titleEn: json['title_en'] as String? ?? '',
        titleAr: json['title_ar'] as String?,
        bodyEn: json['body_en'] as String? ?? '',
        bodyAr: json['body_ar'] as String?,
        type: json['type'] as String? ?? 'general',
        entityId: json['entity_id'] == null
            ? null
            : (json['entity_id'] as num).toInt(),
        createdAt: json['created_at'] as String? ?? '',
      );
}

class NotificationItemModel extends NotificationItem {
  const NotificationItemModel({
    required super.id,
    required super.notificationId,
    required super.isRead,
    super.readAt,
    required super.createdAt,
    required super.notification,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) =>
      NotificationItemModel(
        id: json['id'] as int,
        notificationId: json['notification_id'] as int,
        isRead: json['is_read'] as bool? ?? false,
        readAt: json['read_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        notification: NotificationDataModel.fromJson(
          json['notification'] as Map<String, dynamic>,
        ),
      );
}
