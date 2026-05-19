import 'package:equatable/equatable.dart';

abstract class AiAdsEvent extends Equatable {
  const AiAdsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAiAds extends AiAdsEvent {
  const LoadAiAds();
}

class DeleteAiAd extends AiAdsEvent {
  final int id;
  const DeleteAiAd(this.id);
  @override
  List<Object?> get props => [id];
}
