import 'package:equatable/equatable.dart';

abstract class AiAdDetailEvent extends Equatable {
  const AiAdDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadAiAdDetail extends AiAdDetailEvent {
  final int id;
  const LoadAiAdDetail(this.id);
  @override
  List<Object?> get props => [id];
}

class RefreshAiAdDetail extends AiAdDetailEvent {
  final int id;
  const RefreshAiAdDetail(this.id);
  @override
  List<Object?> get props => [id];
}

class CreateAiAdTrial extends AiAdDetailEvent {
  final int parentId;
  final String caption;
  const CreateAiAdTrial({required this.parentId, required this.caption});
  @override
  List<Object?> get props => [parentId, caption];
}

class CheckAiAdPayment extends AiAdDetailEvent {
  final int id;
  const CheckAiAdPayment(this.id);
  @override
  List<Object?> get props => [id];
}
