import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repository;

  HomeBloc({required this.repository}) : super(HomeInitial()) {
    on<GetPostsEvent>(_onGetPosts);
  }

  Future<void> _onGetPosts(
    GetPostsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    final result = await repository.getPosts();
    result.fold(
      (failure) => emit(HomeError(message: _mapFailureToMessage(failure))),
      (posts) => emit(HomeLoaded(posts: posts)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return switch (failure) {
      ServerFailure _ => AppStrings.serverError,
      CacheFailure _ => AppStrings.cacheError,
      NetworkFailure _ => AppStrings.networkError,
      _ => AppStrings.unexpectedError,
    };
  }
}
