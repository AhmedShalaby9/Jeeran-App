import 'package:equatable/equatable.dart';
import '../../domain/entities/user_subscription.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionSuccess extends SubscriptionState {
  final UserSubscription subscription;
  const SubscriptionSuccess(this.subscription);
  @override
  List<Object?> get props => [subscription];
}

class UpgradeSubscriptionSuccess extends SubscriptionState {
  final UserSubscription subscription;
  const UpgradeSubscriptionSuccess(this.subscription);
  @override
  List<Object?> get props => [subscription];
}

class CancelSubscriptionSuccess extends SubscriptionState {}

class SubscriptionHistoryLoading extends SubscriptionState {}

class SubscriptionHistoryLoaded extends SubscriptionState {
  final List<UserSubscription> history;
  const SubscriptionHistoryLoaded(this.history);
  @override
  List<Object?> get props => [history];
}

class SubscriptionHistoryError extends SubscriptionState {
  final String message;
  const SubscriptionHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}

class MySubscriptionLoading extends SubscriptionState {}

class MySubscriptionLoaded extends SubscriptionState {
  final UserSubscription subscription;
  const MySubscriptionLoaded(this.subscription);
  @override
  List<Object?> get props => [subscription];
}

class MySubscriptionError extends SubscriptionState {
  final String message;
  const MySubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}
