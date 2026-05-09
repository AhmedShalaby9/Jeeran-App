import '../../domain/entities/notification_item.dart';

abstract class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationItem> items;
  final bool hasMore;
  final int page;

  const NotificationLoaded({
    required this.items,
    required this.hasMore,
    required this.page,
  });

  NotificationLoaded copyWith({
    List<NotificationItem>? items,
    bool? hasMore,
    int? page,
  }) =>
      NotificationLoaded(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
      );
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
}
