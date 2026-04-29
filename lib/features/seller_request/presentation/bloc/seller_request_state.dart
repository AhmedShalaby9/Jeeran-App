import 'package:equatable/equatable.dart';

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
