import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  static const int _pageSize = 20;

  NotificationBloc({required this.repository}) : super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoad);
    on<LoadMoreNotifications>(_onLoadMore);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAll);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());
    final result = await repository.getNotifications(page: 1, limit: _pageSize);
    result.fold(
      (f) => emit(NotificationError((f as dynamic).message as String? ?? 'Failed to load notifications')),
      (items) => emit(NotificationLoaded(
        items: items,
        hasMore: items.length >= _pageSize,
        page: 1,
      )),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationLoaded || !current.hasMore) return;
    final nextPage = current.page + 1;
    final result = await repository.getNotifications(page: nextPage, limit: _pageSize);
    result.fold(
      (_) {},
      (newItems) => emit(current.copyWith(
        items: [...current.items, ...newItems],
        hasMore: newItems.length >= _pageSize,
        page: nextPage,
      )),
    );
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationLoaded) return;

    // Optimistic update
    final updated = current.items.map((item) {
      if (item.id == event.receiptId) return item.copyWith(isRead: true);
      return item;
    }).toList();
    emit(current.copyWith(items: updated));

    await repository.markRead(event.receiptId);
  }

  Future<void> _onMarkAll(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationLoaded) return;

    // Optimistic update
    final updated = current.items
        .map((item) => item.copyWith(isRead: true))
        .toList();
    emit(current.copyWith(items: updated));

    await repository.markAllRead();
  }
}
