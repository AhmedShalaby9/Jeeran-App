import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/news.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_data_source.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NewsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<News>>> getNews() async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final news = await remoteDataSource.getNews();
      return Right(news);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
