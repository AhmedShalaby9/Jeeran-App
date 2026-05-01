import 'package:equatable/equatable.dart';
import '../../../projects/domain/entities/project.dart';

class Property extends Equatable {
  final int id;
  final int? legacyId;
  final String? legacyCode;
  final String titleAr;
  final String titleEn;
  final String? slug;
  final String? contentAr;
  final String? contentEn;
  final String? contentHtml;
  final String? propertyType;
  final String? propertyStatus;
  final String? price;
  final String? size;
  final int? bedrooms;
  final int? bathrooms;
  final String? country;
  final String? state;
  final int? projectId;
  final List<String> images;
  final String? videoUrl;
  final bool isFeatured;
  final bool isActive;
  final bool isFavorited;
  final String? publishedAt;
  final int? viewsCount;
  final String? agentName;
  final String? agentMobile;
  final String? agentWhatsapp;
  final String? agentEmail;
  final String? agentPicture;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final Project? project;

  const Property({
    required this.id,
    this.legacyId,
    this.legacyCode,
    this.titleAr = '',
    this.titleEn = '',
    this.slug,
    this.contentAr,
    this.contentEn,
    this.contentHtml,
    this.propertyType,
    this.propertyStatus,
    this.price,
    this.size,
    this.bedrooms,
    this.bathrooms,
    this.country,
    this.state,
    this.projectId,
    required this.images,
    this.videoUrl,
    this.isFeatured = false,
    this.isActive = true,
    this.isFavorited = false,
    this.publishedAt,
    this.viewsCount,
    this.agentName,
    this.agentMobile,
    this.agentWhatsapp,
    this.agentEmail,
    this.agentPicture,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.project,
  });

  String? get coverImage => images.isNotEmpty ? images.first : null;

  /// Returns the title in [lang] (e.g. 'ar' or 'en').
  /// Falls back to the other language if the requested one is empty.
  String localTitle(String lang) {
    if (lang == 'ar') {
      return titleAr.isNotEmpty ? titleAr : titleEn;
    }
    return titleEn.isNotEmpty ? titleEn : titleAr;
  }

  /// Returns the content in [lang], falling back to the other language.
  String? localContent(String lang) {
    if (lang == 'ar') {
      final ar = contentAr;
      return (ar != null && ar.isNotEmpty) ? ar : contentEn;
    }
    final en = contentEn;
    return (en != null && en.isNotEmpty) ? en : contentAr;
  }

  @override
  List<Object?> get props => [
        id,
        legacyId,
        legacyCode,
        titleAr,
        titleEn,
        slug,
        contentAr,
        contentEn,
        contentHtml,
        propertyType,
        propertyStatus,
        price,
        size,
        bedrooms,
        bathrooms,
        country,
        state,
        projectId,
        images,
        videoUrl,
        isFeatured,
        isActive,
        isFavorited,
        publishedAt,
        viewsCount,
        agentName,
        agentMobile,
        agentWhatsapp,
        agentEmail,
        agentPicture,
        createdBy,
        createdAt,
        updatedAt,
        project,
      ];
}
