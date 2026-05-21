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
    // Upload new media files first
    final uploadedUrls = <String>[];
    for (int i = 0; i < event.newMedia.length; i++) {
      emit(NewsUploading(current: i + 1, total: event.newMedia.length));
      final uploadResult = await repository.uploadMedia(event.newMedia[i].path);
      String? url;
      uploadResult.fold((f) => url = null, (u) => url = u);
      if (url == null) {
        emit(NewsActionError('Failed to upload media ${i + 1}. Please try again.'));
        return;
      }
      uploadedUrls.add(url!);
    }

    emit(NewsLoading());
    final result = await repository.createNews({
      'title_ar': event.titleAr,
      if (event.titleEn != null) 'title_en': event.titleEn,
      'content_ar': event.contentAr,
      if (event.contentEn != null) 'content_en': event.contentEn,
      'is_active': event.isActive,
      if (uploadedUrls.isNotEmpty) 'media': uploadedUrls,
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
    // Upload new media files first
    final allMediaUrls = <String>[...event.existingMediaUrls];
    for (int i = 0; i < event.newMedia.length; i++) {
      emit(NewsUploading(current: i + 1, total: event.newMedia.length));
      final uploadResult = await repository.uploadMedia(event.newMedia[i].path);
      String? url;
      uploadResult.fold((f) => url = null, (u) => url = u);
      if (url == null) {
        emit(NewsActionError('Failed to upload media ${i + 1}. Please try again.'));
        return;
      }
      allMediaUrls.add(url!);
    }

    emit(NewsLoading());
    final result = await repository.updateNews(event.id, {
      'title_ar': event.titleAr,
      if (event.titleEn != null) 'title_en': event.titleEn,
      'content_ar': event.contentAr,
      if (event.contentEn != null) 'content_en': event.contentEn,
      'is_active': event.isActive,
      'media': allMediaUrls,
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
