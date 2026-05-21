import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
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

class SubmitUpdateProperty extends AddPropertyEvent {
  final int propertyId;
  final List<String> existingImageUrls;
  final List<XFile> newImages;
  final Map<String, dynamic> body;

  const SubmitUpdateProperty({
    required this.propertyId,
    required this.existingImageUrls,
    required this.newImages,
    required this.body,
  });

  @override
  List<Object?> get props => [propertyId, existingImageUrls, newImages, body];
}
