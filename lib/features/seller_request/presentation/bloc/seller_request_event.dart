import 'package:equatable/equatable.dart';

abstract class SellerRequestEvent extends Equatable {
  const SellerRequestEvent();
  @override
  List<Object?> get props => [];
}

class SubmitSellerRequestEvent extends SellerRequestEvent {
  const SubmitSellerRequestEvent();
}

class FetchSellerRequestsEvent extends SellerRequestEvent {
  final String? status; // 'pending' | 'approved' | 'rejected' | null (all)
  const FetchSellerRequestsEvent({this.status});
  @override
  List<Object?> get props => [status];
}

class ApproveSellerRequestEvent extends SellerRequestEvent {
  final int id;
  const ApproveSellerRequestEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class RejectSellerRequestEvent extends SellerRequestEvent {
  final int id;
  const RejectSellerRequestEvent(this.id);
  @override
  List<Object?> get props => [id];
}
