import 'package:equatable/equatable.dart';
import '../widgets/add_property_form.dart';

abstract class AddPropertyEvent extends Equatable {
  const AddPropertyEvent();
  @override
  List<Object?> get props => [];
}

class SubmitAddProperty extends AddPropertyEvent {
  final AddPropertyForm form;
  const SubmitAddProperty({required this.form});
  @override
  List<Object?> get props => [form];
}
