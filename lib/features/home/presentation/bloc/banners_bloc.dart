import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/home_repository.dart';
import 'banners_event.dart';
import 'banners_state.dart';

class BannersBloc extends Bloc<BannersEvent, BannersState> {
  final HomeRepository repository;

  BannersBloc({required this.repository}) : super(BannersInitial()) {
    on<FetchBannersEvent>(_onFetchBanners);
  }

  Future<void> _onFetchBanners(
    FetchBannersEvent event,
    Emitter<BannersState> emit,
  ) async {
    if (state is BannersLoading || state is BannersLoaded) return;
    emit(BannersLoading());
    final result = await repository.getBanners();
    result.fold(
      (_) => emit(BannersError()),
      (banners) => emit(BannersLoaded(banners)),
    );
  }
}
