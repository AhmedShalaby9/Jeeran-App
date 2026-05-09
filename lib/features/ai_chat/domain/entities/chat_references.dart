import 'package:equatable/equatable.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../projects/domain/entities/project.dart';

class ChatReferences extends Equatable {
  final List<Property> properties;
  final List<Project> projects;
  final List<ChatNewsRef> news;

  const ChatReferences({
    required this.properties,
    required this.projects,
    required this.news,
  });

  bool get isEmpty =>
      properties.isEmpty && projects.isEmpty && news.isEmpty;

  @override
  List<Object?> get props => [properties, projects, news];
}

class ChatNewsRef extends Equatable {
  final int id;
  final String titleAr;
  final String titleEn;
  final String contentAr;

  const ChatNewsRef({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
  });

  String localTitle(String lang) {
    if (lang == 'ar' && titleAr.isNotEmpty) return titleAr;
    return titleEn.isNotEmpty ? titleEn : titleAr;
  }

  @override
  List<Object?> get props => [id, titleAr, titleEn, contentAr];
}
