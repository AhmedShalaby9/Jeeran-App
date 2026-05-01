import 'package:equatable/equatable.dart';

class ChatSession extends Equatable {
  final int id;
  final int userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, userId, title, createdAt, updatedAt];
}
