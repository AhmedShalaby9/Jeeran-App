import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../properties/domain/entities/property_filter_params.dart';
import '../../../properties/presentation/pages/properties_screen.dart';
import '../../domain/entities/project.dart';
import '../widgets/project_description_section.dart';
import '../widgets/project_details_app_bar.dart';
import '../widgets/project_features_section.dart';
import '../widgets/project_gallery_section.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Project project;
  const ProjectDetailsPage({super.key, required this.project});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late final PageController _galleryController;
  Timer? _autoScrollTimer;
  int _currentGalleryPage = 0;

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
    if (widget.project.gallery.length > 1) _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final nextPage =
          (_currentGalleryPage + 1) % widget.project.gallery.length;
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
    final project = widget.project;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 44,
        child: FloatingActionButton.extended(
          onPressed: () {
            final params = PropertyFilterParams(
              projectId: widget.project.id,
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PropertiesScreen(params: params)),
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
            style: TextStyle(
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
