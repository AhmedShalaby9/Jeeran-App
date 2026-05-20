import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_ad.dart';

abstract class AiAdDetailState extends Equatable {
  const AiAdDetailState();
  @override
  List<Object?> get props => [];
}

class AiAdDetailInitial extends AiAdDetailState {}
class AiAdDetailLoading extends AiAdDetailState {}

class AiAdDetailLoaded extends AiAdDetailState {
  final AiAd ad;
  final List<AiAd> trials;
  final bool isCreatingTrial;
  final bool isCheckingPayment;
  final String? trialError;

  const AiAdDetailLoaded({
    required this.ad,
    required this.trials,
    this.isCreatingTrial = false,
    this.isCheckingPayment = false,
    this.trialError,
  });

  AiAdDetailLoaded copyWith({
    AiAd? ad,
    List<AiAd>? trials,
    bool? isCreatingTrial,
    bool? isCheckingPayment,
    String? trialError,
    bool clearTrialError = false,
  }) {
    return AiAdDetailLoaded(
      ad: ad ?? this.ad,
      trials: trials ?? this.trials,
      isCreatingTrial: isCreatingTrial ?? this.isCreatingTrial,
      isCheckingPayment: isCheckingPayment ?? this.isCheckingPayment,
      trialError: clearTrialError ? null : (trialError ?? this.trialError),
    );
  }

  @override
  List<Object?> get props => [ad, trials, isCreatingTrial, isCheckingPayment, trialError];
}

class AiAdDetailError extends AiAdDetailState {
  final String message;
  const AiAdDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class AiAdTrialCreated extends AiAdDetailState {
  final AiAd trial;
  const AiAdTrialCreated(this.trial);
  @override
  List<Object?> get props => [trial];
}
