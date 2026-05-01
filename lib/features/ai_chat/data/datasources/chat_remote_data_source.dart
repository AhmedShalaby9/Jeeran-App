import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatSessionModel> createSession(String title);
  Future<List<ChatSessionModel>> getSessions({int page = 1, int limit = 20});
  Future<List<ChatMessageModel>> getMessages(int sessionId);
  Future<ChatMessageModel> sendMessage(int sessionId, String content);
  Future<void> deleteSession(int sessionId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;
  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ChatSessionModel> createSession(String title) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.chatSessions,
        data: {'title': title},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data as Map<String, dynamic>;
        return ChatSessionModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<List<ChatSessionModel>> getSessions({int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.chatSessions,
        queryParams: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(ChatSessionModel.fromJson)
            .toList();
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(int sessionId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.chatMessages(sessionId),
      );
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map((j) => ChatMessageModel.fromJson(j, fallbackSessionId: sessionId))
            .toList();
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<ChatMessageModel> sendMessage(int sessionId, String content) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.chatMessages(sessionId),
        data: {'content': content},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        return ChatMessageModel.fromJson(data, fallbackSessionId: sessionId);
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    try {
      final response = await apiClient.delete(
        ApiEndpoints.chatSessionById(sessionId),
      );
      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
