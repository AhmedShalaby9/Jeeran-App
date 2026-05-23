import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/ads_repository.dart';
import 'ads_event.dart';
import 'ads_state.dart';

class AdsBloc extends Bloc<AdsEvent, AdsState> {
  final AdsRepository repository;

  AdsBloc({required this.repository}) : super(AdsInitial()) {
    on<FetchAdsEvent>(_onFetch);
  }

  Future<void> _onFetch(FetchAdsEvent event, Emitter<AdsState> emit) async {
    if (state is AdsLoading || state is AdsLoaded) return;
    emit(AdsLoading());
    final result = await repository.getAds();
    result.fold(
      (failure) => emit(AdsError(_mapFailure(failure))),
      (ads) => emit(AdsLoaded(ads)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure f => f.message ?? AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
