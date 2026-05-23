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
  Future<Either<Failure, User>> login(String phone, {String? fcmToken, String? platform, String? deviceId}) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.login(phone, fcmToken: fcmToken, platform: platform, deviceId: deviceId);
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
  Future<Either<Failure, bool>> sendOtp(String phone) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final isNewUser = await remoteDataSource.sendOtp(phone);
      return Right(isNewUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> verifyOtp(String phone, String otp, {String? fcmToken, String? platform, String? deviceId}) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final user = await remoteDataSource.verifyOtp(phone, otp, fcmToken: fcmToken, platform: platform, deviceId: deviceId);
      _saveToken(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> firebaseVerify(String idToken, {String? fcmToken, String? platform, String? deviceId}) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final user = await remoteDataSource.firebaseVerify(idToken, fcmToken: fcmToken, platform: platform, deviceId: deviceId);
      _saveToken(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> sendOtpRest(String phone, String recaptchaToken) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final sessionInfo = await remoteDataSource.sendOtpRest(phone, recaptchaToken);
      return Right(sessionInfo);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> verifyOtpRest(String sessionInfo, String code, {String? fcmToken, String? platform, String? deviceId}) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final user = await remoteDataSource.verifyOtpRest(sessionInfo, code, fcmToken: fcmToken, platform: platform, deviceId: deviceId);
      _saveToken(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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
