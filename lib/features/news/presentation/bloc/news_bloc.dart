import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/news_repository.dart';
import 'news_event.dart';
import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsRepository repository;

  NewsBloc({required this.repository}) : super(NewsInitial()) {
    on<FetchNewsEvent>(_onFetchNews);
    on<RefreshNewsEvent>(_onRefreshNews);
    on<CreateNewsEvent>(_onCreateNews);
    on<UpdateNewsEvent>(_onUpdateNews);
    on<DeleteNewsEvent>(_onDeleteNews);
  }

  Future<void> _onFetchNews(
    FetchNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    if (state is NewsLoading || state is NewsLoaded) return;
    emit(NewsLoading());
    final result = await repository.getNews();
    result.fold(
      (failure) => emit(NewsError(_mapFailure(failure))),
      (news) => emit(NewsLoaded(news)),
    );
  }

  Future<void> _onRefreshNews(
    RefreshNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoading());
    final result = await repository.getNews();
    result.fold(
      (failure) => emit(NewsError(_mapFailure(failure))),
      (news) => emit(NewsLoaded(news)),
    );
  }

  Future<void> _onCreateNews(
    CreateNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoading());
    final result = await repository.createNews({
      'title_ar': event.titleAr,
      if (event.titleEn != null) 'title_en': event.titleEn,
      'content_ar': event.contentAr,
      if (event.contentEn != null) 'content_en': event.contentEn,
      'is_active': event.isActive,
    });
    result.fold(
      (failure) => emit(NewsActionError(_mapFailure(failure))),
      (_) => emit(NewsActionSuccess()),
    );
  }

  Future<void> _onUpdateNews(
    UpdateNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoading());
    final result = await repository.updateNews(event.id, {
      'title_ar': event.titleAr,
      if (event.titleEn != null) 'title_en': event.titleEn,
      'content_ar': event.contentAr,
      if (event.contentEn != null) 'content_en': event.contentEn,
      'is_active': event.isActive,
    });
    result.fold(
      (failure) => emit(NewsActionError(_mapFailure(failure))),
      (_) => emit(NewsActionSuccess()),
    );
  }

  Future<void> _onDeleteNews(
    DeleteNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoading());
    final result = await repository.deleteNews(event.id);
    result.fold(
      (failure) => emit(NewsActionError(_mapFailure(failure))),
      (_) => emit(NewsActionSuccess()),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure f => f.message ?? AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
