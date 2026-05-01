import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_session.dart';

abstract class ChatSessionsState extends Equatable {
  const ChatSessionsState();
  @override
  List<Object?> get props => [];
}

class ChatSessionsInitial extends ChatSessionsState {}

class ChatSessionsLoading extends ChatSessionsState {}

class ChatSessionsLoaded extends ChatSessionsState {
  final List<ChatSession> sessions;
  const ChatSessionsLoaded(this.sessions);
  @override
  List<Object?> get props => [sessions];
}

class ChatSessionsError extends ChatSessionsState {
  final String message;
  const ChatSessionsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatSessionDeleting extends ChatSessionsState {
  final List<ChatSession> sessions;
  final int deletingId;
  const ChatSessionDeleting(this.sessions, this.deletingId);
  @override
  List<Object?> get props => [sessions, deletingId];
}
