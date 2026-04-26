import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_posts.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/projects/data/datasources/project_remote_data_source.dart';
import '../../features/projects/data/repositories/project_repository_impl.dart';
import '../../features/projects/domain/repositories/project_repository.dart';
import '../../features/projects/domain/usecases/get_projects.dart';
import '../../features/projects/presentation/bloc/projects_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── BLoC ──────────────────────────────────────────────
  sl.registerFactory(() => HomeBloc(getPosts: sl()));
  sl.registerFactory(() => ProjectsBloc(getProjects: sl()));

  // ── Use cases ─────────────────────────────────────────
  sl.registerLazySingleton(() => GetPosts(sl()));
  sl.registerLazySingleton(() => GetProjects(sl()));

  // ── Repositories ──────────────────────────────────────
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // ── Data sources ──────────────────────────────────────
  sl.registerLazySingleton<ProjectRemoteDataSource>(
    () => ProjectRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(),
  );

  // ── Core ──────────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
  sl.registerLazySingleton(() => ApiClient());

  // ── External ──────────────────────────────────────────
  sl.registerLazySingleton(() => InternetConnection());
}
