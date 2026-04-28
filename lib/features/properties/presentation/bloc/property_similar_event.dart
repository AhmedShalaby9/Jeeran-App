import 'package:equatable/equatable.dart';

abstract class PropertySimilarEvent extends Equatable {
  const PropertySimilarEvent();
  @override
  List<Object?> get props => [];
}

class FetchPropertySimilarEvent extends PropertySimilarEvent {
  final int propertyId;
  const FetchPropertySimilarEvent(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}
