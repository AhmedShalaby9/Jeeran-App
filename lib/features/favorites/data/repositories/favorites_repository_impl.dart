import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  FavoritesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Property>>> getFavorites() async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getFavorites();
      return Right(result);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addFavorite(int propertyId) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.addFavorite(propertyId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeFavorite(int propertyId) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.removeFavorite(propertyId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
