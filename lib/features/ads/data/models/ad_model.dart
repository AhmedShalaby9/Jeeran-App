import '../../domain/entities/ad.dart';

class AdModel extends Ad {
  const AdModel({
    required super.id,
    required super.title,
    required super.name,
    super.description,
    required super.images,
    super.phoneNumber,
    super.whatsappNumber,
    required super.isActive,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.whereType<String>().toList()
        : <String>[];

    return AdModel(
      id: json['id'] as int,
      title: (json['title'] as String?)?.isNotEmpty == true
          ? json['title'] as String
          : json['title_en'] as String? ?? '',
      name: (json['name'] as String?)?.isNotEmpty == true
          ? json['name'] as String
          : json['name_en'] as String? ?? '',
      description: json['description'] as String?,
      images: images,
      phoneNumber: json['phone_number'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
