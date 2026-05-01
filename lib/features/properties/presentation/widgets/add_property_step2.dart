import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/bloc/projects_bloc.dart';
import '../../../projects/presentation/bloc/projects_event.dart';
import '../../../projects/presentation/bloc/projects_state.dart';
import '../../domain/enums/property_enums.dart';
import 'add_property_form.dart';

class AddPropertyStep2 extends StatefulWidget {
  final AddPropertyForm form;
  final VoidCallback onChanged;

  const AddPropertyStep2({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  State<AddPropertyStep2> createState() => _AddPropertyStep2State();
}

class _AddPropertyStep2State extends State<AddPropertyStep2> {
  void _update(VoidCallback fn) {
    fn();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProjectsBloc>()..add(const FetchProjectsEvent()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WizardStepTitle(
            'Location & project',
            subtitle: 'Where is the property and which project does it belong to?',
          ),

          // ── State / City ─────────────────────────────────────────
          const WizardLabel('State / City', required: true),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PropertyState.options.map((s) {
              return WizardChip(
                label: s.label(),
                active: widget.form.location == s,
                onTap: () => _update(() => widget.form.location = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // ── Project selection ─────────────────────────────────────
          const WizardLabel('Project', required: true),
          BlocBuilder<ProjectsBloc, ProjectsState>(
            builder: (context, state) {
              if (state is ProjectsLoading || state is ProjectsInitial) {
                return const _ProjectLoadingPlaceholder();
              }
              if (state is ProjectsError) {
                return _ProjectErrorPlaceholder(
                  message: state.message,
                  onRetry: () =>
                      context.read<ProjectsBloc>().add(const FetchProjectsEvent()),
                );
              }
              if (state is ProjectsLoaded) {
                final projects = state.projects;
                if (projects.isEmpty) {
                  return const _EmptyProjects();
                }
                return _ProjectList(
                  projects: projects,
                  selectedId: widget.form.projectId,
                  onSelect: (p) => _update(() {
                    widget.form.projectId = p.id;
                    widget.form.projectTitle = p.name;
                  }),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// ── Project list ──────────────────────────────────────────────

class _ProjectList extends StatelessWidget {
  final List<Project> projects;
  final int? selectedId;
  final ValueChanged<Project> onSelect;

  const _ProjectList({
    required this.projects,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: projects.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        final active = selectedId == p.id;
        return Padding(
          padding: EdgeInsets.only(bottom: i < projects.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.hairline,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Cover image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: p.coverImage != null
                        ? Image.network(
                            p.coverImage!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ProjectImageFallback(active: active),
                          )
                        : _ProjectImageFallback(active: active),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.primary : AppColors.ink,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: active ? AppColors.primary : const Color(0xFFD5DAE2),
                        width: 2,
                      ),
                    ),
                    child: active
                        ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProjectImageFallback extends StatelessWidget {
  final bool active;
  const _ProjectImageFallback({required this.active});

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: active
          ? AppColors.primary.withValues(alpha: 0.12)
          : const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      Icons.domain_rounded,
      size: 22,
      color: active ? AppColors.primary : AppColors.inkMute,
    ),
  );
}

// ── Loading / error / empty states ────────────────────────────

class _ProjectLoadingPlaceholder extends StatelessWidget {
  const _ProjectLoadingPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      3,
      (_) => Container(
        height: 76,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline),
        ),
      ),
    ),
  );
}

class _ProjectErrorPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProjectErrorPlaceholder({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5F5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
        ),
        GestureDetector(
          onTap: onRetry,
          child: const Text(
            'Retry',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(
      child: Text(
        'No projects found.',
        style: TextStyle(fontSize: 14, color: AppColors.inkSub),
      ),
    ),
  );
}
