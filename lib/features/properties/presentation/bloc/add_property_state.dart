import 'package:equatable/equatable.dart';

abstract class AddPropertyState extends Equatable {
  const AddPropertyState();
  @override
  List<Object?> get props => [];
}

class AddPropertyInitial extends AddPropertyState {
  const AddPropertyInitial();
}

class AddPropertyUploading extends AddPropertyState {
  final int current;
  final int total;
  const AddPropertyUploading({required this.current, required this.total});
  @override
  List<Object?> get props => [current, total];
}

class AddPropertySubmitting extends AddPropertyState {
  const AddPropertySubmitting();
}

class AddPropertySuccess extends AddPropertyState {
  const AddPropertySuccess();
}

class AddPropertyFailure extends AddPropertyState {
  final String message;
  const AddPropertyFailure(this.message);
  @override
  List<Object?> get props => [message];
}
