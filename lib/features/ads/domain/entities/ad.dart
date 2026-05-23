import 'package:equatable/equatable.dart';

class Ad extends Equatable {
  final int id;
  final String title;
  final String name;
  final String? description;
  final List<String> images;
  final String? phoneNumber;
  final String? whatsappNumber;
  final bool isActive;

  const Ad({
    required this.id,
    required this.title,
    required this.name,
    this.description,
    required this.images,
    this.phoneNumber,
    this.whatsappNumber,
    required this.isActive,
  });

  String? get coverImage => images.isNotEmpty ? images.first : null;

  @override
  List<Object?> get props => [id, title, name, description, images, phoneNumber, whatsappNumber, isActive];
}
