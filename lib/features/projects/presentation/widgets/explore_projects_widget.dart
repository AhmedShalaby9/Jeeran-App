import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/project.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_state.dart';
import 'project_card.dart';

class ExploreProjectsWidget extends StatelessWidget {
  final String? title;
  const ExploreProjectsWidget({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return _ExploreProjectsView(title: title);
  }
}

class _ExploreProjectsView extends StatefulWidget {
  final String? title;
  const _ExploreProjectsView({this.title});

  @override
  State<_ExploreProjectsView> createState() => _ExploreProjectsViewState();
}

class _ExploreProjectsViewState extends State<_ExploreProjectsView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;
  double _scrollPosition = 0;
  bool _scrollingForward = true;

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isUserScrolling && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (_scrollingForward) {
          _scrollPosition += 0.5;
          if (_scrollPosition >= maxScroll) {
            _scrollPosition = maxScroll;
            _scrollingForward = false;
          }
        } else {
          _scrollPosition -= 0.5;
          if (_scrollPosition <= 0) {
            _scrollPosition = 0;
            _scrollingForward = true;
          }
        }
        _scrollController.jumpTo(_scrollPosition);
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectsBloc, ProjectsState>(
      listener: (context, state) {
        if (state is ProjectsLoaded && state.projects.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _startAutoScroll(),
          );
        }
      },
      builder: (context, state) {
        if (state is ProjectsLoading) {
          return SizedBox(
            height: 160,
            child: Center(child: AppLoading.cupertino()),
          );
        }
        if (state is ProjectsLoaded && state.projects.isNotEmpty) {
          return _buildContent(state.projects);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(List<Project> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title ?? 'projects.explore'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserScrolling = true;
              } else if (notification is ScrollEndNotification) {
                _isUserScrolling = false;
                _scrollPosition = _scrollController.offset;
              }
              return false;
            },
            child: ListView.separated(
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: projects.length,
              itemBuilder: (_, i) => SizedBox(
                width: 140,
                child: ProjectCard(project: projects[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
