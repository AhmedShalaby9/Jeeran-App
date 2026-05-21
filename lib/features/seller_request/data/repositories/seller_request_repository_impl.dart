import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/seller_request_repository.dart';
import '../datasources/seller_request_remote_data_source.dart';
import '../models/seller_request_model.dart';

class SellerRequestRepositoryImpl implements SellerRequestRepository {
  final SellerRequestRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SellerRequestRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> submitSellerRequest() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }
    try {
      await remoteDataSource.submitSellerRequest();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<SellerRequestModel>>> getSellerRequests({String? status}) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final requests = await remoteDataSource.getSellerRequests(status: status);
      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> approveSellerRequest(int id) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.approveSellerRequest(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> rejectSellerRequest(int id) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.rejectSellerRequest(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
