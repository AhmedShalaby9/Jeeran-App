import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/ai_ad.dart';
import '../../domain/repositories/ai_ads_repository.dart';
import '../datasources/ai_ads_remote_data_source.dart';

class AiAdsRepositoryImpl implements AiAdsRepository {
  final AiAdsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AiAdsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> generate({
    required String caption,
    required List<String> sourceImages,
    required String language,
    bool isAdmin = false,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final data = await remoteDataSource.generate(
        caption: caption,
        sourceImages: sourceImages,
        language: language,
        isAdmin: isAdmin,
      );
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<AiAd>>> listAds({
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.listAds(page: page, limit: limit));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AiAd>> getAd(int id) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.getAd(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAd(int id) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.deleteAd(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AiAd>> createTrial({
    required int parentId,
    required String caption,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.createTrial(
        parentId: parentId,
        caption: caption,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<AiAd>>> listTrials(int parentId) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.listTrials(parentId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AiAd>> checkPayment(int id) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      return Right(await remoteDataSource.checkPayment(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
