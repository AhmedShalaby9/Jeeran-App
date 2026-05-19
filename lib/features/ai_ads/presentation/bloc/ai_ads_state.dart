import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_ad.dart';

abstract class AiAdsState extends Equatable {
  const AiAdsState();
  @override
  List<Object?> get props => [];
}

class AiAdsInitial extends AiAdsState {}
class AiAdsLoading extends AiAdsState {}

class AiAdsLoaded extends AiAdsState {
  final List<AiAd> ads;
  const AiAdsLoaded(this.ads);
  @override
  List<Object?> get props => [ads];
}

class AiAdsDeleting extends AiAdsState {
  final List<AiAd> ads;
  final int deletingId;
  const AiAdsDeleting(this.ads, this.deletingId);
  @override
  List<Object?> get props => [ads, deletingId];
}

class AiAdsError extends AiAdsState {
  final String message;
  const AiAdsError(this.message);
  @override
  List<Object?> get props => [message];
}
