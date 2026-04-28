import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/project.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_event.dart';
import '../bloc/projects_state.dart';
import '../widgets/project_card.dart';
import '../widgets/projects_error_view.dart';
import '../widgets/projects_shimmer.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  static bool _initialized = false;

  void _ensureLoaded() {
    if (_initialized) return;
    _initialized = true;
    sl<ProjectsBloc>().add(const FetchProjectsEvent());
  }

  @override
  Widget build(BuildContext context) {
    _ensureLoaded();
    return BlocProvider.value(
      value: sl<ProjectsBloc>(),
      child: const _ProjectsView(),
    );
  }
}

class _ProjectsView extends StatelessWidget {
  const _ProjectsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('projects.title'.tr())),
      backgroundColor: AppColors.background,
      body: BlocBuilder<ProjectsBloc, ProjectsState>(
        builder: (context, state) {
          if (state is ProjectsLoading) return const ProjectsShimmer();
          if (state is ProjectsError) {
            return ProjectsErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<ProjectsBloc>().add(const FetchProjectsEvent()),
            );
          }
          if (state is ProjectsLoaded) {
            return _ProjectsGrid(projects: state.projects);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ProjectsGrid extends StatelessWidget {
  final List<Project> projects;
  const _ProjectsGrid({required this.projects});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: projects.length,
      itemBuilder: (_, i) => ProjectCard(project: projects[i]),
    );
  }
}
