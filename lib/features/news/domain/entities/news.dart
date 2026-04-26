import 'package:equatable/equatable.dart';

class News extends Equatable {
  final int id;
  final String title;
  final String content;
  final List<String> media;
  final bool isActive;
  final String publishedAt;
  final String publishedBy;

  const News({
    required this.id,
    required this.title,
    required this.content,
    required this.media,
    required this.isActive,
    required this.publishedAt,
    required this.publishedBy,
  });

  String? get coverMedia => media.isNotEmpty ? media.first : null;

  @override
  List<Object?> get props =>
      [id, title, content, media, isActive, publishedAt, publishedBy];
}
