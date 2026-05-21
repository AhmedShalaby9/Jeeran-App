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

class ApprovePropertyEvent extends PropertiesEvent {
  final int id;
  const ApprovePropertyEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class RejectPropertyEvent extends PropertiesEvent {
  final int id;
  final String rejectionReason;
  const RejectPropertyEvent(this.id, this.rejectionReason);
  @override
  List<Object?> get props => [id, rejectionReason];
}
