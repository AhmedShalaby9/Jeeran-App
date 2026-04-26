import '../../domain/entities/news.dart';

class NewsModel extends News {
  const NewsModel({
    required super.id,
    required super.title,
    required super.content,
    required super.media,
    required super.isActive,
    required super.publishedAt,
    required super.publishedBy,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final media = rawMedia is List
        ? rawMedia.whereType<String>().toList()
        : <String>[];

    return NewsModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      media: media,
      isActive: json['is_active'] as bool? ?? true,
      publishedAt: json['published_at'] as String? ?? '',
      publishedBy: json['published_by'] as String? ?? '',
    );
  }
}
