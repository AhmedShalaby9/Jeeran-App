import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_data_source.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProjectRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Project>>> getProjects() async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final projects = await remoteDataSource.getProjects();
      return Right(projects);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Project>> getProjectById(int id) async {
    if (!await networkInfo.isConnected) return Left(NetworkFailure());
    try {
      final project = await remoteDataSource.getProjectById(id);
      return Right(project);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
