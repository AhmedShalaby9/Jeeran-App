import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_session.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  /// POST /chat/sessions — title is optional (null = backend default)
  Future<Either<Failure, ChatSession>> createSession({String? title});

  /// GET /chat/sessions?page=&limit=
  Future<Either<Failure, List<ChatSession>>> getSessions({
    int page = 1,
    int limit = 20,
  });

  /// GET /chat/sessions/{id}
  Future<Either<Failure, ChatSession>> getSession(int sessionId);

  /// GET /chat/sessions/{id}/messages?page=&limit=
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    int sessionId, {
    int page = 1,
    int limit = 20,
  });

  /// POST /chat/sessions/{id}/messages
  Future<Either<Failure, ChatMessage>> sendMessage(
      int sessionId, String content);

  /// DELETE /chat/sessions/{id}
  Future<Either<Failure, void>> deleteSession(int sessionId);
}
