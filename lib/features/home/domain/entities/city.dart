import 'package:equatable/equatable.dart';

class City extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? image;
  final int propertiesCount;

  const City({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.image,
    required this.propertiesCount,
  });

  String get name => nameEn.isNotEmpty ? nameEn : nameAr;

  @override
  List<Object?> get props => [id, nameAr, nameEn, image, propertiesCount];
}
