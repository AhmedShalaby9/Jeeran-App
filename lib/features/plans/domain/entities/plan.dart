import 'package:equatable/equatable.dart';

class PlanFeature extends Equatable {
  final String ar;
  final String en;

  const PlanFeature({required this.ar, required this.en});

  String localized(String languageCode) => languageCode == 'ar' ? ar : en;

  @override
  List<Object?> get props => [ar, en];
}

class Plan extends Equatable {
  final int id;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final String price;
  final int durationDays;
  final int availableListings;
  final int featuredListings;
  final List<PlanFeature> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Plan({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.price,
    required this.durationDays,
    required this.availableListings,
    required this.featuredListings,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String localizedName(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;

  String localizedDescription(String languageCode) =>
      languageCode == 'ar' ? descriptionAr : descriptionEn;

  @override
  List<Object?> get props => [
        id,
        nameEn,
        nameAr,
        descriptionEn,
        descriptionAr,
        price,
        durationDays,
        availableListings,
        featuredListings,
        features,
        isActive,
        createdAt,
        updatedAt,
      ];
}
