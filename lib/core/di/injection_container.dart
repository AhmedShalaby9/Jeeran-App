import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_banners.dart';
import '../../features/home/domain/usecases/get_posts.dart';
import '../../features/home/presentation/bloc/banners_bloc.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/news/data/datasources/news_remote_data_source.dart';
import '../../features/news/data/repositories/news_repository_impl.dart';
import '../../features/news/domain/repositories/news_repository.dart';
import '../../features/news/domain/usecases/get_news.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../../features/projects/data/datasources/project_remote_data_source.dart';
import '../../features/projects/data/repositories/project_repository_impl.dart';
import '../../features/projects/domain/repositories/project_repository.dart';
import '../../features/projects/domain/usecases/get_projects.dart';
import '../../features/projects/presentation/bloc/projects_bloc.dart';
import '../../features/properties/data/datasources/property_remote_data_source.dart';
import '../../features/properties/data/repositories/property_repository_impl.dart';
import '../../features/properties/domain/repositories/property_repository.dart';
import '../../features/properties/domain/usecases/get_properties.dart';
import '../../features/properties/presentation/bloc/properties_bloc.dart';
import '../../features/subscription/data/datasources/plan_remote_data_source.dart';
import '../../features/subscription/data/repositories/plan_repository_impl.dart';
import '../../features/subscription/domain/repositories/plan_repository.dart';
import '../../features/subscription/domain/usecases/get_plans.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // -- BLoC ----------------------------------------------
  sl.registerFactory(() => HomeBloc(getPosts: sl()));
  sl.registerFactory(() => BannersBloc(getBanners: sl()));
  sl.registerFactory(() => ProjectsBloc(getProjects: sl()));
  sl.registerFactory(() => PropertiesBloc(getProperties: sl()));
  sl.registerFactory(() => NewsBloc(getNews: sl()));

  // -- Use cases -----------------------------------------
  sl.registerLazySingleton(() => GetPosts(sl()));
  sl.registerLazySingleton(() => GetBanners(sl()));
  sl.registerLazySingleton(() => GetProjects(sl()));
  sl.registerLazySingleton(() => GetProperties(sl()));
  sl.registerLazySingleton(() => GetNews(sl()));
  sl.registerLazySingleton(() => GetPlans(sl()));

  // -- Repositories --------------------------------------
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
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<NewsRepository>(
    () => NewsRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<PlanRepository>(
    () => PlanRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // -- Data sources --------------------------------------
  sl.registerLazySingleton<ProjectRemoteDataSource>(
    () => ProjectRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<PropertyRemoteDataSource>(
    () => PropertyRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<NewsRemoteDataSource>(
    () => NewsRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<PlanRemoteDataSource>(
    () => PlanRemoteDataSourceImpl(apiClient: sl()),
  );

  // -- Core ----------------------------------------------
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
  sl.registerLazySingleton(() => ApiClient());

  // -- External ------------------------------------------
  sl.registerLazySingleton(() => InternetConnection());
}
