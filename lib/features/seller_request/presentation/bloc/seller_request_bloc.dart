import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/seller_request_repository.dart';
import 'seller_request_event.dart';
import 'seller_request_state.dart';

class SellerRequestBloc extends Bloc<SellerRequestEvent, SellerRequestState> {
  final SellerRequestRepository repository;

  SellerRequestBloc({required this.repository}) : super(SellerRequestInitial()) {
    on<SubmitSellerRequestEvent>(_onSubmit);
  }

  Future<void> _onSubmit(
    SubmitSellerRequestEvent event,
    Emitter<SellerRequestState> emit,
  ) async {
    emit(SellerRequestLoading());
    final result = await repository.submitSellerRequest();
    result.fold(
      (failure) => emit(SellerRequestError(_mapFailure(failure))),
      (_) => emit(SellerRequestSuccess()),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure f => f.message ?? AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
