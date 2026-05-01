import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_session.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatSession>> createSession(String title);
  Future<Either<Failure, List<ChatSession>>> getSessions({int page = 1, int limit = 20});
  Future<Either<Failure, List<ChatMessage>>> getMessages(int sessionId);
  Future<Either<Failure, ChatMessage>> sendMessage(int sessionId, String content);
  Future<Either<Failure, void>> deleteSession(int sessionId);
}
