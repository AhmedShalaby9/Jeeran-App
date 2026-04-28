import 'package:equatable/equatable.dart';
import '../../domain/entities/plan.dart';

abstract class PlansState extends Equatable {
  const PlansState();
  @override
  List<Object?> get props => [];
}

class PlansInitial extends PlansState {}

class PlansLoading extends PlansState {}

class PlansLoaded extends PlansState {
  final List<Plan> plans;
  const PlansLoaded(this.plans);
  @override
  List<Object?> get props => [plans];
}

class PlansError extends PlansState {
  final String message;
  const PlansError(this.message);
  @override
  List<Object?> get props => [message];
}
