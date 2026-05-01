import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<LoadChat>(_onLoad);
    on<SendChatMessage>(_onSend);
  }

  // ── Load existing session messages ─────────────────────────────────────────
  Future<void> _onLoad(LoadChat event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final result = await repository.getMessages(event.session.id);
    result.fold(
      (failure) => emit(ChatError(_mapFailure(failure))),
      (messages) => emit(ChatReady(
        session: event.session,
        messages: messages.reversed.toList(),
      )),
    );
  }

  // ── Send chat ───────────────────────────────────────────────────────────
  Future<void> _onSend(SendChatMessage event, Emitter<ChatState> emit) async {
    // ── Case A: brand-new session (no session object yet) ──────────────────
    if (event.session == null) {
      final title = event.content.length > 60
          ? '${event.content.substring(0, 60)}…'
          : event.content;

      // 1. Create session via API
      final sessionResult = await repository.createSession(title: title);
      if (sessionResult.isLeft()) {
        String errMsg = 'Failed to create session.';
        sessionResult.fold((f) => errMsg = _mapFailure(f), (_) {});
        emit(ChatError(errMsg));
        return;
      }
      final session = sessionResult.getOrElse(() => throw Exception());

      // 2. Show optimistic user chat + typing indicator
      final optimisticUser = _optimistic(event.content, session.id);
      emit(ChatReady(session: session, messages: [optimisticUser], isSending: true));

      // 3. Send chat — get AI reply
      final msgResult = await repository.sendMessage(session.id, event.content);
      msgResult.fold(
        (f) => emit(ChatReady(
          session: session,
          messages: [optimisticUser],
          sendError: _mapFailure(f),
        )),
        (aiMsg) => emit(ChatReady(
          session: session,
          messages: [optimisticUser, aiMsg],
        )),
      );
      return;
    }

    // ── Case B: existing session ───────────────────────────────────────────
    final current = state;
    if (current is! ChatReady) return;

    final optimisticUser = _optimistic(event.content, event.session!.id);
    emit(current.copyWith(
      messages: [...current.messages, optimisticUser],
      isSending: true,
      sendError: null,
    ));

    final msgResult =
        await repository.sendMessage(event.session!.id, event.content);
    msgResult.fold(
      (f) => emit(current.copyWith(
        messages: [...current.messages, optimisticUser],
        isSending: false,
        sendError: _mapFailure(f),
      )),
      (aiMsg) => emit(current.copyWith(
        messages: [...current.messages, optimisticUser, aiMsg],
        isSending: false,
      )),
    );
  }

  ChatMessage _optimistic(String content, int sessionId) => ChatMessage(
        id: -DateTime.now().millisecondsSinceEpoch,
        sessionId: sessionId,
        content: content,
        role: 'user',
        createdAt: DateTime.now(),
      );

  String _mapFailure(dynamic failure) {
    final msg = (failure?.message as String?) ?? '';
    return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
  }
}
