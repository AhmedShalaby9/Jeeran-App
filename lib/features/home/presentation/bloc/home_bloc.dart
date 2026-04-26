import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/usecases/get_posts.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetPosts getPosts;

  HomeBloc({required this.getPosts}) : super(HomeInitial()) {
    on<GetPostsEvent>(_onGetPosts);
  }

  Future<void> _onGetPosts(
    GetPostsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    final result = await getPosts(NoParams());
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
