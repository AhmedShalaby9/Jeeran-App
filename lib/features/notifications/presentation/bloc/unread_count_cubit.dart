import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';

class UnreadCountCubit extends Cubit<int> {
  final NotificationRepository repository;

  UnreadCountCubit({required this.repository}) : super(0);

  Future<void> fetch() async {
    final result = await repository.getUnreadCount();
    result.fold((_) {}, (count) => emit(count));
  }

  void increment() => emit(state + 1);

  void reset() => emit(0);

  void decrement() {
    if (state > 0) emit(state - 1);
  }
}
