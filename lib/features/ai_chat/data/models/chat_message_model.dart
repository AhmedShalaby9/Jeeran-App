import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.sessionId,
    required super.content,
    required super.role,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json,
      {int? fallbackSessionId}) {
    return ChatMessageModel(
      id: json['id'] as int,
      sessionId: json['session_id'] as int? ?? fallbackSessionId ?? 0,
      content: json['content'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Build an AI reply message from the send-message response.
  /// { "reply": "...", "usage": {...}, "session_id": N }
  factory ChatMessageModel.fromReply({
    required String reply,
    required int sessionId,
  }) {
    return ChatMessageModel(
      id: -DateTime.now().millisecondsSinceEpoch, // synthetic — API has no id here
      sessionId: sessionId,
      content: reply,
      role: 'assistant',
      createdAt: DateTime.now(),
    );
  }
}
