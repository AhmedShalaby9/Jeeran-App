import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SubscriptionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserSubscription>> createSubscription({required int packageId}) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final result = await remoteDataSource.createSubscription(packageId: packageId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserSubscription>> upgradeSubscription({required int packageId}) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final result = await remoteDataSource.upgradeSubscription(packageId: packageId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription() async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      await remoteDataSource.cancelSubscription();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<UserSubscription>>> getSubscriptionHistory() async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getSubscriptionHistory();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserSubscription>> getMySubscription() async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getMySubscription();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserSubscription>> submitPaymentProof({
    required int subscriptionId,
    required String filePath,
  }) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final result = await remoteDataSource.submitPaymentProof(
        subscriptionId: subscriptionId,
        filePath: filePath,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
