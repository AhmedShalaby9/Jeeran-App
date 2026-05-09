import '../../../properties/data/models/property_model.dart';
import '../../../projects/data/models/project_model.dart';
import '../../domain/entities/chat_references.dart';

class ChatReferencesModel extends ChatReferences {
  const ChatReferencesModel({
    required super.properties,
    required super.projects,
    required super.news,
  });

  factory ChatReferencesModel.fromJson(Map<String, dynamic> json) {
    final rawProperties = json['properties'];
    final rawProjects = json['projects'];
    final rawNews = json['news'];

    return ChatReferencesModel(
      properties: rawProperties is List
          ? rawProperties
              .whereType<Map<String, dynamic>>()
              .map(_parseProperty)
              .toList()
          : [],
      projects: rawProjects is List
          ? rawProjects
              .whereType<Map<String, dynamic>>()
              .map(ProjectModel.fromJson)
              .toList()
          : [],
      news: rawNews is List
          ? rawNews
              .whereType<Map<String, dynamic>>()
              .map(_parseNewsRef)
              .toList()
          : [],
    );
  }

  // The references API may return price/size as numbers — normalize to String
  // so PropertyModel.fromJson (which expects String?) handles them correctly.
  static PropertyModel _parseProperty(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);
    if (m['price'] is num) m['price'] = m['price'].toString();
    if (m['size'] is num) m['size'] = m['size'].toString();
    return PropertyModel.fromJson(m);
  }

  static ChatNewsRef _parseNewsRef(Map<String, dynamic> json) => ChatNewsRef(
        id: json['id'] as int,
        titleAr: json['title_ar'] as String? ?? '',
        titleEn: json['title_en'] as String? ?? '',
        contentAr: json['content_ar'] as String? ?? '',
      );
}
