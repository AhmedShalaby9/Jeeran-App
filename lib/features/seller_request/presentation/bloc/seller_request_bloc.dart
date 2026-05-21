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
    on<FetchSellerRequestsEvent>(_onFetchSellerRequests);
    on<ApproveSellerRequestEvent>(_onApprove);
    on<RejectSellerRequestEvent>(_onReject);
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

  Future<void> _onFetchSellerRequests(
    FetchSellerRequestsEvent event,
    Emitter<SellerRequestState> emit,
  ) async {
    emit(SellerRequestLoading());
    final result = await repository.getSellerRequests(status: event.status);
    result.fold(
      (failure) => emit(SellerRequestError(_mapFailure(failure))),
      (requests) => emit(SellerRequestsLoaded(requests)),
    );
  }

  Future<void> _onApprove(
    ApproveSellerRequestEvent event,
    Emitter<SellerRequestState> emit,
  ) async {
    emit(SellerRequestLoading());
    final result = await repository.approveSellerRequest(event.id);
    result.fold(
      (failure) => emit(SellerRequestError(_mapFailure(failure))),
      (_) => emit(SellerRequestActionSuccess()),
    );
  }

  Future<void> _onReject(
    RejectSellerRequestEvent event,
    Emitter<SellerRequestState> emit,
  ) async {
    emit(SellerRequestLoading());
    final result = await repository.rejectSellerRequest(event.id);
    result.fold(
      (failure) => emit(SellerRequestError(_mapFailure(failure))),
      (_) => emit(SellerRequestActionSuccess()),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure f => f.message ?? AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
