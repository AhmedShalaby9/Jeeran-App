import 'package:equatable/equatable.dart';
import 'chat_references.dart';

class ChatMessage extends Equatable {
  final int id;
  final int sessionId;
  final String content;
  final String role; // 'user' | 'assistant'
  final DateTime createdAt;
  final ChatReferences? references;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.role,
    required this.createdAt,
    this.references,
  });

  bool get isUser => role == 'user';

  @override
  List<Object?> get props => [id, sessionId, content, role, createdAt, references];
}
