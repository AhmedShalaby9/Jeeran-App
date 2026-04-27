import 'package:equatable/equatable.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_filter_params.dart';

abstract class PropertiesState extends Equatable {
  const PropertiesState();
  @override
  List<Object?> get props => [];
}

class PropertiesInitial extends PropertiesState {}

class PropertiesLoading extends PropertiesState {}

class PropertiesLoaded extends PropertiesState {
  final List<Property> properties;
  final int currentPage;
  final bool hasReachedMax;
  final PropertyFilterParams params;

  const PropertiesLoaded({
    required this.properties,
    this.currentPage = 1,
    this.hasReachedMax = false,
    required this.params,
  });

  PropertiesLoaded copyWith({
    List<Property>? properties,
    int? currentPage,
    bool? hasReachedMax,
    PropertyFilterParams? params,
  }) {
    return PropertiesLoaded(
      properties: properties ?? this.properties,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      params: params ?? this.params,
    );
  }

  @override
  List<Object?> get props => [properties, currentPage, hasReachedMax, params];
}

class PropertiesLoadingMore extends PropertiesState {
  final List<Property> currentProperties;
  final PropertyFilterParams params;
  const PropertiesLoadingMore(this.currentProperties, {required this.params});
  @override
  List<Object?> get props => [currentProperties, params];
}

class PropertiesError extends PropertiesState {
  final String message;
  const PropertiesError(this.message);
  @override
  List<Object?> get props => [message];
}
