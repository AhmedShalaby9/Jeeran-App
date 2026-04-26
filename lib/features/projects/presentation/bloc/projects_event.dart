import 'package:equatable/equatable.dart';

abstract class ProjectsEvent extends Equatable {
  const ProjectsEvent();
  @override
  List<Object?> get props => [];
}

class FetchProjectsEvent extends ProjectsEvent {
  const FetchProjectsEvent();
}
