import 'package:equatable/equatable.dart';

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

  const CreateNewsEvent({
    required this.titleAr,
    this.titleEn,
    required this.contentAr,
    this.contentEn,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [titleAr, titleEn, contentAr, contentEn, isActive];
}

class UpdateNewsEvent extends NewsEvent {
  final int id;
  final String titleAr;
  final String? titleEn;
  final String contentAr;
  final String? contentEn;
  final bool isActive;

  const UpdateNewsEvent({
    required this.id,
    required this.titleAr,
    this.titleEn,
    required this.contentAr,
    this.contentEn,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, titleAr, titleEn, contentAr, contentEn, isActive];
}

class DeleteNewsEvent extends NewsEvent {
  final int id;
  const DeleteNewsEvent(this.id);
  @override
  List<Object?> get props => [id];
}
