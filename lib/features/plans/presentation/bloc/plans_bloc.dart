import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/plan_repository.dart';
import 'plans_event.dart';
import 'plans_state.dart';

class PlansBloc extends Bloc<PlansEvent, PlansState> {
  final PlanRepository repository;

  PlansBloc({required this.repository}) : super(PlansInitial()) {
    on<FetchPlansEvent>(_onFetchPlans);
  }

  Future<void> _onFetchPlans(
    FetchPlansEvent event,
    Emitter<PlansState> emit,
  ) async {
    emit(PlansLoading());
    final result = await repository.getPlans();
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
