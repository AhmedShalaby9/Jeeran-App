import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/chat_session.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

/// Loading existing session messages.
class ChatLoading extends ChatState {}

/// Session is ready — messages loaded and chat is interactive.
class ChatReady extends ChatState {
  final ChatSession session;
  final List<ChatMessage> messages;

  /// True while waiting for the AI reply (show typing indicator).
  final bool isSending;

  /// Set after a send error (inline — doesn't replace screen).
  final String? sendError;

  const ChatReady({
    required this.session,
    required this.messages,
    this.isSending = false,
    this.sendError,
  });

  ChatReady copyWith({
    ChatSession? session,
    List<ChatMessage>? messages,
    bool? isSending,
    String? sendError,
  }) {
    return ChatReady(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      sendError: sendError,
    );
  }

  @override
  List<Object?> get props => [session, messages, isSending, sendError];
}

/// Full-screen error (loading failed).
class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}
