import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ai_ads_repository.dart';
import 'ai_ads_event.dart';
import 'ai_ads_state.dart';

class AiAdsBloc extends Bloc<AiAdsEvent, AiAdsState> {
  final AiAdsRepository repository;

  AiAdsBloc({required this.repository}) : super(AiAdsInitial()) {
    on<LoadAiAds>(_onLoad);
    on<DeleteAiAd>(_onDelete);
  }

  Future<void> _onLoad(LoadAiAds event, Emitter<AiAdsState> emit) async {
    emit(AiAdsLoading());
    final result = await repository.listAds();
    result.fold(
      (failure) => emit(AiAdsError(_mapFailure(failure))),
      (ads) => emit(AiAdsLoaded(ads)),
    );
  }

  Future<void> _onDelete(DeleteAiAd event, Emitter<AiAdsState> emit) async {
    final current = state;
    if (current is! AiAdsLoaded) return;

    emit(AiAdsDeleting(current.ads, event.id));
    final result = await repository.deleteAd(event.id);
    result.fold(
      (_) => emit(AiAdsLoaded(current.ads)),
      (_) => emit(AiAdsLoaded(
        current.ads.where((a) => a.id != event.id).toList(),
      )),
    );
  }

  String _mapFailure(dynamic failure) {
    final msg = (failure?.message as String?) ?? '';
    return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
  }
}
