import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/property_repository.dart';
import 'properties_event.dart';
import 'properties_state.dart';

class MyPropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  final PropertyRepository repository;

  MyPropertiesBloc({required this.repository}) : super(PropertiesInitial()) {
    on<FetchPropertiesEvent>(_onFetch);
    on<LoadMorePropertiesEvent>(_onLoadMore);
  }

  Future<void> _onFetch(
    FetchPropertiesEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is PropertiesLoaded && currentState.params == event.params) {
      return;
    }
    emit(PropertiesLoading());
    final result = await repository.getMyProperties(event.params);
    result.fold(
      (failure) => emit(PropertiesError(_mapFailure(failure))),
      (properties) => emit(PropertiesLoaded(
        properties: properties,
        currentPage: event.params.page ?? 1,
        hasReachedMax: properties.length < (event.params.perPage ?? 20),
        params: event.params,
      )),
    );
  }

  Future<void> _onLoadMore(
    LoadMorePropertiesEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PropertiesLoaded || currentState.hasReachedMax) return;

    emit(PropertiesLoadingMore(currentState.properties, params: currentState.params));

    final nextPage = currentState.currentPage + 1;
    final params = currentState.params.copyWith(page: nextPage);

    final result = await repository.getMyProperties(params);
    result.fold(
      (_) => emit(currentState),
      (newProperties) {
        if (newProperties.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(PropertiesLoaded(
            properties: [...currentState.properties, ...newProperties],
            currentPage: nextPage,
            hasReachedMax: newProperties.length < (params.perPage ?? 20),
            params: currentState.params,
          ));
        }
      },
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure f => f.message ?? AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
