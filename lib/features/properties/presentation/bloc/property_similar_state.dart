import 'package:equatable/equatable.dart';
import '../../domain/entities/property.dart';

abstract class PropertySimilarState extends Equatable {
  const PropertySimilarState();
  @override
  List<Object?> get props => [];
}

class PropertySimilarInitial extends PropertySimilarState {}

class PropertySimilarLoading extends PropertySimilarState {}

class PropertySimilarLoaded extends PropertySimilarState {
  final List<Property> properties;
  const PropertySimilarLoaded(this.properties);
  @override
  List<Object?> get props => [properties];
}

class PropertySimilarError extends PropertySimilarState {
  final String message;
  const PropertySimilarError(this.message);
  @override
  List<Object?> get props => [message];
}
