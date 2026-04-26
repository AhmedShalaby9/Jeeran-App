import '../../domain/entities/city.dart';

class CityModel extends City {
  const CityModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    super.image,
    required super.propertiesCount,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      image: json['image'] as String?,
      propertiesCount: json['properties_count'] as int? ?? 0,
    );
  }
}
