import 'package:equatable/equatable.dart';

abstract class ChatSessionsEvent extends Equatable {
  const ChatSessionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadChatSessions extends ChatSessionsEvent {
  const LoadChatSessions();
}

class DeleteChatSession extends ChatSessionsEvent {
  final int sessionId;
  const DeleteChatSession(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}
