import 'package:equatable/equatable.dart';

/// The developer a project belongs to (as embedded by the API).
class ProjectDeveloper extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? logo;

  const ProjectDeveloper({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.logo,
  });

  String get name => nameEn.isNotEmpty ? nameEn : nameAr;

  @override
  List<Object?> get props => [id, nameAr, nameEn, logo];
}

class Project extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? mainImage;
  final List<String> gallery;
  final List<ProjectFeature> features;
  final String? descAr;
  final String? descEn;
  final bool isActive;

  // v2 — developer backlink + "new launch" strip data
  final ProjectDeveloper? developer;
  final bool isNewLaunch;
  final String? state;
  final String? areaAr;
  final String? areaEn;
  final double? minPrice; // starting sale price over visible listings
  final int? unitsCount;

  const Project({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.gallery,
    required this.features,
    required this.isActive,
    this.mainImage,
    this.descAr,
    this.descEn,
    this.developer,
    this.isNewLaunch = false,
    this.state,
    this.areaAr,
    this.areaEn,
    this.minPrice,
    this.unitsCount,
  });

  /// "Sidi Abdelrahman" if the admin set one, else the state, else null.
  String? get areaLabel {
    final a = (areaEn != null && areaEn!.isNotEmpty) ? areaEn : areaAr;
    if (a != null && a.isNotEmpty) return a;
    switch (state) {
      case 'north_coast':
        return 'North Coast';
      case 'cairo':
        return 'Cairo';
      case 'sharm_el_sheikh':
        return 'Sharm El Sheikh';
    }
    return null;
  }

  String get name => nameEn.isNotEmpty ? nameEn : nameAr;
  String get description => descEn ?? descAr ?? '';
  String? get coverImage => mainImage ?? (gallery.isNotEmpty ? gallery.first : null);

  @override
  List<Object?> get props => [
        id, nameAr, nameEn, mainImage, gallery, features, descAr, descEn, isActive,
        developer, isNewLaunch, state, areaAr, areaEn, minPrice, unitsCount,
      ];
}

class ProjectFeature extends Equatable {
  final List<String> images;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String? descAr;
  final String? descEn;

  const ProjectFeature({
    required this.images,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    this.descAr,
    this.descEn,
  });

  String get title => titleEn.isNotEmpty ? titleEn : titleAr;
  String get subtitle => subtitleEn.isNotEmpty ? subtitleEn : subtitleAr;

  @override
  List<Object?> get props => [images, titleAr, titleEn, subtitleAr, subtitleEn];
}
