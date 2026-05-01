import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionBloc({required this.repository}) : super(SubscriptionInitial()) {
    on<CreateSubscriptionEvent>(_onCreate);
    on<FetchMySubscriptionEvent>(_onFetch);
  }

  Future<void> _onCreate(
    CreateSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    final result = await repository.createSubscription(packageId: event.packageId);
    result.fold(
      (failure) => emit(SubscriptionError(
        failure is ServerFailure
            ? (failure.message ?? 'errors.server'.tr())
            : 'errors.network'.tr(),
      )),
      (_) => emit(SubscriptionSuccess()),
    );
  }

  Future<void> _onFetch(
    FetchMySubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(MySubscriptionLoading());
    final result = await repository.getMySubscription();
    result.fold(
      (failure) => emit(MySubscriptionError(
        failure is ServerFailure
            ? (failure.message ?? 'errors.server'.tr())
            : 'errors.network'.tr(),
      )),
      (subscription) => emit(MySubscriptionLoaded(subscription)),
    );
  }
}
