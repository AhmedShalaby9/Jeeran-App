import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Post>>> getPosts() async {
    if (await networkInfo.isConnected) {
      try {
        final posts = await remoteDataSource.getPosts();
        await localDataSource.cachePosts(posts);
        return Right(posts);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final posts = await localDataSource.getCachedPosts();
        return Right(posts);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
