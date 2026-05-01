import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_sessions_event.dart';
import 'chat_sessions_state.dart';

class ChatSessionsBloc extends Bloc<ChatSessionsEvent, ChatSessionsState> {
  final ChatRepository repository;

  ChatSessionsBloc({required this.repository}) : super(ChatSessionsInitial()) {
    on<LoadChatSessions>(_onLoad);
    on<DeleteChatSession>(_onDelete);
  }

  Future<void> _onLoad(
    LoadChatSessions event,
    Emitter<ChatSessionsState> emit,
  ) async {
    emit(ChatSessionsLoading());
    final result = await repository.getSessions();
    result.fold(
      (failure) => emit(ChatSessionsError(_mapFailure(failure))),
      (sessions) => emit(ChatSessionsLoaded(sessions)),
    );
  }

  Future<void> _onDelete(
    DeleteChatSession event,
    Emitter<ChatSessionsState> emit,
  ) async {
    final current = state;
    if (current is! ChatSessionsLoaded) return;

    emit(ChatSessionDeleting(current.sessions, event.sessionId));

    final result = await repository.deleteSession(event.sessionId);
    result.fold(
      (_) => emit(ChatSessionsLoaded(current.sessions)), // restore on failure
      (_) => emit(ChatSessionsLoaded(
        current.sessions.where((s) => s.id != event.sessionId).toList(),
      )),
    );
  }

  String _mapFailure(dynamic failure) {
    final msg = (failure?.message as String?) ?? '';
    if (msg.isNotEmpty) return msg;
    return 'Something went wrong. Please try again.';
  }
}
