import '../../domain/entities/project.dart';

class ProjectFeatureModel extends ProjectFeature {
  const ProjectFeatureModel({
    required super.images,
    required super.titleAr,
    required super.titleEn,
    required super.subtitleAr,
    required super.subtitleEn,
    super.descAr,
    super.descEn,
  });

  factory ProjectFeatureModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.whereType<String>().toList()
        : <String>[];

    return ProjectFeatureModel(
      images: images,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      subtitleAr: json['subtitle_ar'] as String? ?? '',
      subtitleEn: json['subtitle_en'] as String? ?? '',
      descAr: json['desc_ar'] as String?,
      descEn: json['desc_en'] as String?,
    );
  }
}

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.gallery,
    required super.features,
    required super.isActive,
    super.mainImage,
    super.descAr,
    super.descEn,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final rawGallery = json['gallery'];
    final gallery = rawGallery is List
        ? rawGallery.whereType<String>().toList()
        : <String>[];

    final rawFeatures = json['features'];
    final features = rawFeatures is List
        ? rawFeatures
            .whereType<Map<String, dynamic>>()
            .map(ProjectFeatureModel.fromJson)
            .toList()
        : <ProjectFeatureModel>[];

    return ProjectModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      mainImage: json['main_image'] as String?,
      gallery: gallery,
      features: features,
      isActive: json['is_active'] as bool? ?? true,
      descAr: json['desc_ar'] as String?,
      descEn: json['desc_en'] as String?,
    );
  }
}
