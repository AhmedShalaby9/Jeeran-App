import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/usecases/get_projects.dart';
import 'projects_event.dart';
import 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final GetProjects getProjects;

  ProjectsBloc({required this.getProjects}) : super(ProjectsInitial()) {
    on<FetchProjectsEvent>(_onFetchProjects);
  }

  Future<void> _onFetchProjects(
    FetchProjectsEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    final result = await getProjects(NoParams());
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
