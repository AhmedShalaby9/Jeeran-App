import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class CreateSubscriptionEvent extends SubscriptionEvent {
  final int packageId;
  const CreateSubscriptionEvent({required this.packageId});
  @override
  List<Object?> get props => [packageId];
}

class FetchMySubscriptionEvent extends SubscriptionEvent {
  const FetchMySubscriptionEvent();
}
