import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/ad.dart';
import '../../domain/repositories/ads_repository.dart';
import '../datasources/ads_remote_data_source.dart';

class AdsRepositoryImpl implements AdsRepository {
  final AdsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AdsRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, List<Ad>>> getAds() async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final ads = await remoteDataSource.getAds();
      return Right(ads);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Ad>> getAdById(int id) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final ad = await remoteDataSource.getAdById(id);
      return Right(ad);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
