import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/presentation/bloc/banners_bloc.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/news/data/datasources/news_remote_data_source.dart';
import '../../features/news/data/repositories/news_repository_impl.dart';
import '../../features/news/domain/repositories/news_repository.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../../features/plans/presentation/bloc/plans_bloc.dart';
import '../../features/projects/data/datasources/project_remote_data_source.dart';
import '../../features/projects/data/repositories/project_repository_impl.dart';
import '../../features/projects/domain/repositories/project_repository.dart';
import '../../features/projects/presentation/bloc/projects_bloc.dart';
import '../../features/properties/data/datasources/property_remote_data_source.dart';
import '../../features/properties/data/repositories/property_repository_impl.dart';
import '../../features/properties/domain/repositories/property_repository.dart';
import '../../features/properties/presentation/bloc/properties_bloc.dart';
import '../../features/properties/presentation/bloc/property_similar_bloc.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/plans/data/datasources/plan_remote_data_source.dart';
import '../../features/plans/data/repositories/plan_repository_impl.dart';
import '../../features/plans/domain/repositories/plan_repository.dart';
import '../../features/favorites/data/datasources/favorites_remote_data_source.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/seller_request/data/datasources/seller_request_remote_data_source.dart';
import '../../features/seller_request/data/repositories/seller_request_repository_impl.dart';
import '../../features/seller_request/domain/repositories/seller_request_repository.dart';
import '../../features/seller_request/presentation/bloc/seller_request_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // -- BLoC ----------------------------------------------
  sl.registerFactory(() => HomeBloc(repository: sl()));
  sl.registerLazySingleton(() => BannersBloc(repository: sl()));
  sl.registerLazySingleton(() => ProjectsBloc(repository: sl()));
  sl.registerFactory(() => PropertiesBloc(repository: sl()));
  sl.registerFactory(() => PropertySimilarBloc(repository: sl()));
  sl.registerLazySingleton(() => NewsBloc(repository: sl()));
  sl.registerFactory(() => PlansBloc(repository: sl()));
  sl.registerFactory(() => AuthBloc(repository: sl()));
  sl.registerLazySingleton(() => FavoritesBloc(repository: sl()));
  sl.registerFactory(() => SellerRequestBloc(repository: sl()));

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
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<SellerRequestRepository>(
    () => SellerRequestRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
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
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<FavoritesRemoteDataSource>(
    () => FavoritesRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<SellerRequestRemoteDataSource>(
    () => SellerRequestRemoteDataSourceImpl(apiClient: sl()),
  );

// -- Core ----------------------------------------------
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
  sl.registerLazySingleton(() => ApiClient());

  // -- External ------------------------------------------
  sl.registerLazySingleton(
    () => InternetConnection.createInstance(
      useDefaultOptions: false,
      checkInterval: const Duration(seconds: 15),
      customCheckOptions: [
        InternetCheckOption(
          uri: Uri.parse(AppConfig.baseUrl),
          timeout: const Duration(seconds: 5),
          // Any HTTP response (including 4xx) means the server is reachable
          responseStatusFn: (response) =>
              response.statusCode >= 100 && response.statusCode < 600,
        ),
      ],
    ),
  );
}
