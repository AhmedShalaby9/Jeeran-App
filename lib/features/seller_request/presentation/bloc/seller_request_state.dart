import 'package:equatable/equatable.dart';
import '../../data/models/seller_request_model.dart';

abstract class SellerRequestState extends Equatable {
  const SellerRequestState();
  @override
  List<Object?> get props => [];
}

class SellerRequestInitial extends SellerRequestState {}

class SellerRequestLoading extends SellerRequestState {}

class SellerRequestSuccess extends SellerRequestState {}

class SellerRequestError extends SellerRequestState {
  final String message;
  const SellerRequestError(this.message);
  @override
  List<Object?> get props => [message];
}

class SellerRequestsLoaded extends SellerRequestState {
  final List<SellerRequestModel> requests;
  const SellerRequestsLoaded(this.requests);
  @override
  List<Object?> get props => [requests];
}

class SellerRequestActionSuccess extends SellerRequestState {}
