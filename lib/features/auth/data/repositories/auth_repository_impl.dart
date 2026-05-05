import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login(String phone, {String? fcmToken}) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.login(phone, fcmToken: fcmToken);
        _saveToken(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> completeProfile(CompleteProfileParams params) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.completeProfile(params);
        _saveToken(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, User>> getMe() async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getMe();
        // Always overwrite local storage with the authoritative server values.
        // This ensures changes made via the dashboard (e.g. buyer → seller)
        // are picked up without requiring a fresh login.
        await AppStorage.saveUserProfile(
          userId: user.id,
          userName: user.name,
          userType: user.userType,
        );
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  void _saveToken(UserModel user) {
    if (user.token != null) {
      AppStorage.saveAuthTokens(
        token: user.token!,
        userId: user.id,
        userName: user.name,
        userType: user.userType,
      );
    }
  }
}
