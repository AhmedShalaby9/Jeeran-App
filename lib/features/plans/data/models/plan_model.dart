import '../../domain/entities/plan.dart';

class PlanModel extends Plan {
  const PlanModel({
    required super.id,
    required super.nameEn,
    required super.nameAr,
    required super.descriptionEn,
    required super.descriptionAr,
    required super.price,
    required super.durationDays,
    required super.availableListings,
    required super.featuredListings,
    required super.features,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'] as List<dynamic>? ?? [];
    final features = rawFeatures.map((e) {
      if (e is Map<String, dynamic>) {
        return PlanFeature(
          ar: e['ar'] as String? ?? '',
          en: e['en'] as String? ?? '',
        );
      }
      final text = e.toString();
      return PlanFeature(ar: text, en: text);
    }).toList();

    return PlanModel(
      id: json['id'] as int,
      nameEn: json['title_en'] as String? ?? '',
      nameAr: json['title_ar'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionAr: json['description_ar'] as String? ?? '',
      price: json['price'] as String? ?? '',
      durationDays: json['duration_days'] as int? ?? 0,
      availableListings: json['available_listings'] as int? ?? 0,
      featuredListings: json['featured_listings'] as int? ?? 0,
      features: features,
      isActive: json['is_active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
