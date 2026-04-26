import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/usecases/get_news.dart';
import 'news_event.dart';
import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final GetNews getNews;

  NewsBloc({required this.getNews}) : super(NewsInitial()) {
    on<FetchNewsEvent>(_onFetchNews);
  }

  Future<void> _onFetchNews(
    FetchNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoading());
    final result = await getNews(NoParams());
    result.fold(
      (failure) => emit(NewsError(_mapFailure(failure))),
      (news) => emit(NewsLoaded(news)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        NetworkFailure _ => AppStrings.networkError,
        ServerFailure _ => AppStrings.serverError,
        _ => AppStrings.unexpectedError,
      };
}
