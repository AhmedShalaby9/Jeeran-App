import 'package:equatable/equatable.dart';

class News extends Equatable {
  final int id;
  final String title;
  final String content;
  final List<String> media;
  final bool isActive;
  final String publishedAt;
  final String publishedBy;
  // both languages, for the admin editor (title/content are already localized by the API)
  final String titleAr, titleEn, contentAr, contentEn;
  // what this story is tied to, if anything (admin editor only)
  final int? compoundId;
  final int? developerId;

  const News({
    required this.id,
    required this.title,
    required this.content,
    required this.media,
    required this.isActive,
    required this.publishedAt,
    required this.publishedBy,
    this.titleAr = '',
    this.titleEn = '',
    this.contentAr = '',
    this.contentEn = '',
    this.compoundId,
    this.developerId,
  });

  String? get coverMedia => media.isNotEmpty ? media.first : null;

  @override
  List<Object?> get props => [
    id, title, content, media, isActive, publishedAt, publishedBy,
    titleAr, titleEn, contentAr, contentEn, compoundId, developerId,
  ];
}
