import 'package:equatable/equatable.dart';

abstract class BannersEvent extends Equatable {
  const BannersEvent();
  @override
  List<Object?> get props => [];
}

class FetchBannersEvent extends BannersEvent {
  const FetchBannersEvent();
}
