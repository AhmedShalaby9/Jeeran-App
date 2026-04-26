import 'package:equatable/equatable.dart';
import '../../domain/entities/city.dart';

abstract class CitiesState extends Equatable {
  const CitiesState();
  @override
  List<Object?> get props => [];
}

class CitiesInitial extends CitiesState {}

class CitiesLoading extends CitiesState {}

class CitiesLoaded extends CitiesState {
  final List<City> cities;
  const CitiesLoaded(this.cities);
  @override
  List<Object?> get props => [cities];
}

class CitiesError extends CitiesState {
  final String message;
  const CitiesError(this.message);
  @override
  List<Object?> get props => [message];
}
