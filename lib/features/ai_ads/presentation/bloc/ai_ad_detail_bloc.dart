import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ai_ads_repository.dart';
import 'ai_ad_detail_event.dart';
import 'ai_ad_detail_state.dart';

class AiAdDetailBloc extends Bloc<AiAdDetailEvent, AiAdDetailState> {
  final AiAdsRepository repository;

  AiAdDetailBloc({required this.repository}) : super(AiAdDetailInitial()) {
    on<LoadAiAdDetail>(_onLoad);
    on<RefreshAiAdDetail>(_onRefresh);
    on<CreateAiAdTrial>(_onCreateTrial);
  }

  Future<void> _onLoad(
    LoadAiAdDetail event,
    Emitter<AiAdDetailState> emit,
  ) async {
    emit(AiAdDetailLoading());
    await _fetchAndEmit(event.id, emit);
  }

  Future<void> _onRefresh(
    RefreshAiAdDetail event,
    Emitter<AiAdDetailState> emit,
  ) async {
    await _fetchAndEmit(event.id, emit);
  }

  Future<void> _fetchAndEmit(int id, Emitter<AiAdDetailState> emit) async {
    final adResult = await repository.getAd(id);
    if (adResult.isLeft()) {
      String msg = 'Failed to load ad.';
      adResult.fold((f) => msg = _mapFailure(f), (_) {});
      emit(AiAdDetailError(msg));
      return;
    }
    final ad = adResult.getOrElse(() => throw Exception());

    final trialsResult = await repository.listTrials(id);
    final trials = trialsResult.getOrElse(() => []);

    emit(AiAdDetailLoaded(ad: ad, trials: trials));
  }

  Future<void> _onCreateTrial(
    CreateAiAdTrial event,
    Emitter<AiAdDetailState> emit,
  ) async {
    final current = state;
    if (current is! AiAdDetailLoaded) return;

    emit(current.copyWith(isCreatingTrial: true, clearTrialError: true));

    final result = await repository.createTrial(
      parentId: event.parentId,
      caption: event.caption,
    );

    result.fold(
      (failure) => emit(current.copyWith(
        isCreatingTrial: false,
        trialError: _mapFailure(failure),
      )),
      (trial) {
        final updatedTrials = [...current.trials, trial];
        emit(current.copyWith(
          trials: updatedTrials,
          isCreatingTrial: false,
          clearTrialError: true,
        ));
        // Also emit a one-shot success event for snackbar/navigation
        emit(AiAdTrialCreated(trial));
        // Restore loaded state so the page re-renders correctly
        emit(current.copyWith(
          trials: updatedTrials,
          isCreatingTrial: false,
          clearTrialError: true,
        ));
      },
    );
  }

  String _mapFailure(dynamic failure) {
    final msg = (failure?.message as String?) ?? '';
    return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
  }
}
