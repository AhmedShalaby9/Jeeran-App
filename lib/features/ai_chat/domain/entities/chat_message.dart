import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final int id;
  final int sessionId;
  final String content;
  final String role; // 'user' | 'assistant'
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  @override
  List<Object?> get props => [id, sessionId, content, role, createdAt];
}
