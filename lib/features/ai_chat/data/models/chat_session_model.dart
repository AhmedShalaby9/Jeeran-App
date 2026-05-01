import '../../domain/entities/chat_session.dart';

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String? ?? 'New Conversation',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
