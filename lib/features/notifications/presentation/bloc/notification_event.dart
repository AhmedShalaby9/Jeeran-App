abstract class NotificationEvent {
  const NotificationEvent();
}

class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

class LoadMoreNotifications extends NotificationEvent {
  const LoadMoreNotifications();
}

class MarkNotificationRead extends NotificationEvent {
  final int receiptId;
  const MarkNotificationRead(this.receiptId);
}

class MarkAllNotificationsRead extends NotificationEvent {
  const MarkAllNotificationsRead();
}
