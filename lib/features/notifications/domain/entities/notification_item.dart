class NotificationData {
  final int id;
  final String titleEn;
  final String? titleAr;
  final String bodyEn;
  final String? bodyAr;
  final String type;
  final int? entityId;
  final String createdAt;

  const NotificationData({
    required this.id,
    required this.titleEn,
    this.titleAr,
    required this.bodyEn,
    this.bodyAr,
    required this.type,
    this.entityId,
    required this.createdAt,
  });

  String localTitle(String lang) =>
      (lang == 'ar' && titleAr != null && titleAr!.isNotEmpty) ? titleAr! : titleEn;

  String localBody(String lang) =>
      (lang == 'ar' && bodyAr != null && bodyAr!.isNotEmpty) ? bodyAr! : bodyEn;
}

class NotificationItem {
  final int id;
  final int notificationId;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final NotificationData notification;

  const NotificationItem({
    required this.id,
    required this.notificationId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.notification,
  });

  NotificationItem copyWith({bool? isRead, String? readAt}) => NotificationItem(
        id: id,
        notificationId: notificationId,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
        notification: notification,
      );
}
