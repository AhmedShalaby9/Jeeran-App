import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/property_repository.dart';
import 'property_similar_event.dart';
import 'property_similar_state.dart';

class PropertySimilarBloc extends Bloc<PropertySimilarEvent, PropertySimilarState> {
  final PropertyRepository repository;

  PropertySimilarBloc({required this.repository}) : super(PropertySimilarInitial()) {
    on<FetchPropertySimilarEvent>(_onFetch);
  }

  Future<void> _onFetch(FetchPropertySimilarEvent event, Emitter<PropertySimilarState> emit) async {
    emit(PropertySimilarLoading());
    final result = await repository.getSimilarProperties(event.propertyId);
    result.fold(
      (failure) => emit(PropertySimilarError(_mapFailure(failure))),
      (properties) => emit(PropertySimilarLoaded(properties)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure f => f.message ?? AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
