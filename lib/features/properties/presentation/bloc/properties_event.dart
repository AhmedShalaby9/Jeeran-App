import 'package:equatable/equatable.dart';
import '../../domain/entities/property_filter_params.dart';

abstract class PropertiesEvent extends Equatable {
  const PropertiesEvent();
  @override
  List<Object?> get props => [];
}

class FetchPropertiesEvent extends PropertiesEvent {
  final PropertyFilterParams params;
  const FetchPropertiesEvent(this.params);

  @override
  List<Object?> get props => [params];
}

class LoadMorePropertiesEvent extends PropertiesEvent {
  const LoadMorePropertiesEvent();
}

class ResetFiltersEvent extends PropertiesEvent {
  const ResetFiltersEvent();
}
