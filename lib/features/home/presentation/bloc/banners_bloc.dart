import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_banners.dart';
import 'banners_event.dart';
import 'banners_state.dart';

class BannersBloc extends Bloc<BannersEvent, BannersState> {
  final GetBanners getBanners;

  BannersBloc({required this.getBanners}) : super(BannersInitial()) {
    on<FetchBannersEvent>(_onFetchBanners);
  }

  Future<void> _onFetchBanners(
    FetchBannersEvent event,
    Emitter<BannersState> emit,
  ) async {
    emit(BannersLoading());
    final result = await getBanners(NoParams());
    result.fold(
      (_) => emit(BannersError()),
      (banners) => emit(BannersLoaded(banners)),
    );
  }
}
