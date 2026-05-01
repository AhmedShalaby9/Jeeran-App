import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ChatSession>> createSession(String title) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.createSession(title));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChatSession>>> getSessions({
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.getSessions(page: page, limit: limit));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(int sessionId) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.getMessages(sessionId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(
    int sessionId,
    String content,
  ) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.sendMessage(sessionId, content));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(int sessionId) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.deleteSession(sessionId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
