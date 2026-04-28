import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/usecases/get_plans.dart';
import 'plans_event.dart';
import 'plans_state.dart';

class PlansBloc extends Bloc<PlansEvent, PlansState> {
  final GetPlans getPlans;

  PlansBloc({required this.getPlans}) : super(PlansInitial()) {
    on<FetchPlansEvent>(_onFetchPlans);
  }

  Future<void> _onFetchPlans(
    FetchPlansEvent event,
    Emitter<PlansState> emit,
  ) async {
    emit(PlansLoading());
    final result = await getPlans(NoParams());
    result.fold(
      (failure) => emit(PlansError(_mapFailure(failure))),
      (plans) => emit(PlansLoaded(plans)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure _ => AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
