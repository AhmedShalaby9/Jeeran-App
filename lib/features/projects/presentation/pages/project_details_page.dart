import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../properties/domain/entities/property_filter_params.dart';
import '../../../properties/presentation/pages/properties_screen.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../widgets/project_description_section.dart';
import '../widgets/project_details_app_bar.dart';
import '../widgets/project_features_section.dart';
import '../widgets/project_gallery_section.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Project? project;
  final int? projectId;
  final String? displayName;

  // ignore: prefer_initializing_formals
  const ProjectDetailsPage({super.key, required Project project})
      : project = project,
        projectId = null,
        displayName = null;

  const ProjectDetailsPage.fromId({
    super.key,
    required this.projectId,
    required this.displayName,
  }) : project = null;

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late final PageController _galleryController;
  Timer? _autoScrollTimer;
  int _currentGalleryPage = 0;

  Project? _resolved;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
    if (widget.project != null) {
      _resolved = widget.project;
      if (_resolved!.gallery.length > 1) _startAutoScroll();
    } else {
      _loading = true;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    final result =
        await sl<ProjectRepository>().getProjectById(widget.projectId!);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error =
            (failure as dynamic).message as String? ?? 'errors.server'.tr();
      }),
      (project) {
        setState(() {
          _resolved = project;
          _loading = false;
        });
        if (project.gallery.length > 1) _startAutoScroll();
      },
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final nextPage = (_currentGalleryPage + 1) % _resolved!.gallery.length;
      _galleryController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _galleryController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            widget.displayName ?? '',
            style: const TextStyle(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.onBackground),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            widget.displayName ?? '',
            style: const TextStyle(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.onBackground),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 48, color: AppColors.grey),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.inkSub, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('actions.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final project = _resolved!;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 44,
        child: FloatingActionButton.extended(
          onPressed: () {
            final params = PropertyFilterParams(
              projectId: project.id,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PropertiesScreen(params: params)),
            );
          },
          backgroundColor: AppColors.primary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          icon: const Icon(Icons.search, color: Colors.white, size: 18),
          label: Text(
            'project_details.show_all_properties'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          ProjectDetailsAppBar(project: project),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ProjectDescriptionSection(description: project.description),
                ],
                if (project.features.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ProjectFeaturesSection(features: project.features),
                ],
                if (project.gallery.length > 1) ...[
                  const SizedBox(height: 24),
                  ProjectGallerySection(
                    gallery: project.gallery,
                    controller: _galleryController,
                    currentPage: _currentGalleryPage,
                    onPageChanged: (p) =>
                        setState(() => _currentGalleryPage = p),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
