import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class NewsEvent extends Equatable {
  const NewsEvent();
  @override
  List<Object?> get props => [];
}

class FetchNewsEvent extends NewsEvent {
  const FetchNewsEvent();
}

/// Like [FetchNewsEvent] but always re-fetches, ignoring cached state.
class RefreshNewsEvent extends NewsEvent {
  const RefreshNewsEvent();
}

class CreateNewsEvent extends NewsEvent {
  final String titleAr;
  final String? titleEn;
  final String contentAr;
  final String? contentEn;
  final bool isActive;
  final List<XFile> newMedia;

  const CreateNewsEvent({
    required this.titleAr,
    this.titleEn,
    required this.contentAr,
    this.contentEn,
    this.isActive = true,
    this.newMedia = const [],
  });

  @override
  List<Object?> get props => [titleAr, titleEn, contentAr, contentEn, isActive, newMedia];
}

class UpdateNewsEvent extends NewsEvent {
  final int id;
  final String titleAr;
  final String? titleEn;
  final String contentAr;
  final String? contentEn;
  final bool isActive;
  final List<String> existingMediaUrls;
  final List<XFile> newMedia;

  const UpdateNewsEvent({
    required this.id,
    required this.titleAr,
    this.titleEn,
    required this.contentAr,
    this.contentEn,
    this.isActive = true,
    this.existingMediaUrls = const [],
    this.newMedia = const [],
  });

  @override
  List<Object?> get props => [id, titleAr, titleEn, contentAr, contentEn, isActive, existingMediaUrls, newMedia];
}

class DeleteNewsEvent extends NewsEvent {
  final int id;
  const DeleteNewsEvent(this.id);
  @override
  List<Object?> get props => [id];
}
