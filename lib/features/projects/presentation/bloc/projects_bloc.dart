import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/project_repository.dart';
import 'projects_event.dart';
import 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final ProjectRepository repository;

  ProjectsBloc({required this.repository}) : super(ProjectsInitial()) {
    on<FetchProjectsEvent>(_onFetchProjects);
  }

  Future<void> _onFetchProjects(
    FetchProjectsEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    if (state is ProjectsLoading || state is ProjectsLoaded) return;
    emit(ProjectsLoading());
    final result = await repository.getProjects();
    result.fold(
      (failure) => emit(ProjectsError(_mapFailure(failure))),
      (projects) => emit(ProjectsLoaded(projects)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure _ => AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
