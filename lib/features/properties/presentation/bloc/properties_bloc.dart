import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/usecases/get_properties.dart';
import 'properties_event.dart';
import 'properties_state.dart';

class PropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  final GetProperties getProperties;

  PropertiesBloc({required this.getProperties}) : super(PropertiesInitial()) {
    on<FetchPropertiesEvent>(_onFetch);
    on<LoadMorePropertiesEvent>(_onLoadMore);
    on<ResetFiltersEvent>(_onResetFilters);
  }

  Future<void> _onFetch(
    FetchPropertiesEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesLoading());
    final result = await getProperties(event.params);
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

    emit(PropertiesLoadingMore(currentState.properties));

    final nextPage = currentState.currentPage + 1;
    final params = currentState.params.copyWith(page: nextPage);

    final result = await getProperties(params);
    result.fold(
      (_) => emit(currentState), // keep current state on load-more error
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

  Future<void> _onResetFilters(
    ResetFiltersEvent event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesLoading());
    final result = await getProperties(const PropertyFilterParams());
    result.fold(
      (failure) => emit(PropertiesError(_mapFailure(failure))),
      (properties) => emit(PropertiesLoaded(
        properties: properties,
        currentPage: 1,
        hasReachedMax: properties.length < 20,
        params: const PropertyFilterParams(),
      )),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        NetworkFailure _ => AppStrings.networkError,
        ServerFailure _ => AppStrings.serverError,
        _ => AppStrings.unexpectedError,
      };
}
