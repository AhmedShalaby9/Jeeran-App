import '../../domain/entities/app_banner.dart';

class BannerModel extends AppBanner {
  const BannerModel({
    required super.id,
    required super.imageUrl,
    super.link,
    super.phone,
    required super.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String? ?? '',
      link: json['link'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
