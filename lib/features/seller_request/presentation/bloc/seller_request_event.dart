import 'package:equatable/equatable.dart';

abstract class SellerRequestEvent extends Equatable {
  const SellerRequestEvent();
  @override
  List<Object?> get props => [];
}

class SubmitSellerRequestEvent extends SellerRequestEvent {
  const SubmitSellerRequestEvent();
}
