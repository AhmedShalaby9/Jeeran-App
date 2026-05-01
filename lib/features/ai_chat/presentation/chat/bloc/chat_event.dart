import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_session.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

/// Load messages for an existing session.
class LoadChat extends ChatEvent {
  final ChatSession session;
  const LoadChat(this.session);
  @override
  List<Object?> get props => [session];
}

/// Send a chat.
/// [session] is null when this is the very first chat of a new session
/// (the bloc will create the session first, then send).
class SendChatMessage extends ChatEvent {
  final String content;
  final ChatSession? session;
  const SendChatMessage({required this.content, this.session});
  @override
  List<Object?> get props => [content, session];
}
