import '../../../projects/data/models/project_model.dart';
import '../../domain/entities/property.dart';

class PropertyModel extends Property {
  const PropertyModel({
    required super.id,
    super.legacyId,
    super.legacyCode,
    super.titleAr,
    super.titleEn,
    super.slug,
    super.contentAr,
    super.contentEn,
    super.contentHtml,
    super.propertyType,
    super.propertyStatus,
    super.price,
    super.size,
    super.bedrooms,
    super.bathrooms,
    super.country,
    super.state,
    super.projectId,
    required super.images,
    super.videoUrl,
    super.isFeatured,
    super.isActive,
    super.isFavorited,
    super.publishedAt,
    super.viewsCount,
    super.agentName,
    super.agentMobile,
    super.agentWhatsapp,
    super.agentEmail,
    super.agentPicture,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.project,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.whereType<String>().toList()
        : <String>[];

    final rawProject = json['project'];
    final project = rawProject is Map<String, dynamic>
        ? ProjectModel.fromJson(rawProject)
        : null;

    return PropertyModel(
      id: json['id'] as int,
      legacyId: json['legacy_id'] as int?,
      legacyCode: json['legacy_code'] as String?,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      slug: json['slug'] as String?,
      contentAr: json['content_ar'] as String?,
      contentEn: json['content_en'] as String?,
      contentHtml: json['content_html'] as String?,
      propertyType: json['property_type'] as String?,
      propertyStatus: json['property_status'] as String?,
      price: json['price'] as String?,
      size: json['size'] as String?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      projectId: json['project_id'] as int?,
      images: images,
      videoUrl: json['video_url'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isFavorited: json['is_favorited'] as bool? ?? false,
      publishedAt: json['published_at'] as String?,
      viewsCount: json['views_count'] as int?,
      agentName: json['agent_name'] as String?,
      agentMobile: json['agent_mobile'] as String?,
      agentWhatsapp: json['agent_whatsapp'] as String?,
      agentEmail: json['agent_email'] as String?,
      agentPicture: json['agent_picture'] as String?,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      project: project,
    );
  }
}
