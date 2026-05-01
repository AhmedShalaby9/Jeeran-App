import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_remote_data_source.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PropertyRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Property>>> getProperties(
    PropertyFilterParams params,
  ) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final properties = await remoteDataSource.getProperties(params);
      return Right(properties);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Property>>> getMyProperties(
    PropertyFilterParams params,
  ) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final properties = await remoteDataSource.getMyProperties(params);
      return Right(properties);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Property>>> getSimilarProperties(
    int propertyId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final properties = await remoteDataSource.getSimilarProperties(
        propertyId,
        page: page,
        limit: limit,
      );
      return Right(properties);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(String filePath) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final url = await remoteDataSource.uploadImage(filePath);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> createProperty(Map<String, dynamic> data) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.createProperty(data);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
