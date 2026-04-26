import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/usecases/get_cities.dart';
import 'cities_event.dart';
import 'cities_state.dart';

class CitiesBloc extends Bloc<CitiesEvent, CitiesState> {
  final GetCities getCities;

  CitiesBloc({required this.getCities}) : super(CitiesInitial()) {
    on<FetchCitiesEvent>(_onFetchCities);
  }

  Future<void> _onFetchCities(
    FetchCitiesEvent event,
    Emitter<CitiesState> emit,
  ) async {
    emit(CitiesLoading());
    final result = await getCities(NoParams());
    result.fold(
      (failure) => emit(CitiesError(_mapFailure(failure))),
      (cities) => emit(CitiesLoaded(cities)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        NetworkFailure _ => AppStrings.networkError,
        ServerFailure _ => AppStrings.serverError,
        _ => AppStrings.unexpectedError,
      };
}
