import 'package:equatable/equatable.dart';

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
  });

  String get name => nameEn.isNotEmpty ? nameEn : nameAr;
  String get description => descEn ?? descAr ?? '';
  String? get coverImage => mainImage ?? (gallery.isNotEmpty ? gallery.first : null);

  @override
  List<Object?> get props => [id, nameAr, nameEn, mainImage, gallery, features, descAr, descEn, isActive];
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
