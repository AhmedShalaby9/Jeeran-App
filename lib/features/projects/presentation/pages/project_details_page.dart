import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/project.dart';

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
      final nextPage = (_currentGalleryPage + 1) % widget.project.gallery.length;
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, project),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _DescriptionSection(description: project.description),
                ],
                if (project.features.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _FeaturesSection(features: project.features),
                ],
                if (project.gallery.length > 1) ...[
                  const SizedBox(height: 24),
                  _GallerySection(
                    gallery: project.gallery,
                    controller: _galleryController,
                    currentPage: _currentGalleryPage,
                    onPageChanged: (p) => setState(() => _currentGalleryPage = p),
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

  SliverAppBar _buildSliverAppBar(BuildContext context, Project project) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          project.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            project.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: project.coverImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.primary),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.primary,
                      child: const Icon(Icons.business, size: 80, color: Colors.white30),
                    ),
                  )
                : Container(color: AppColors.primary),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gallery ───────────────────────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  final List<String> gallery;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _GallerySection({
    required this.gallery,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Gallery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: controller,
            itemCount: gallery.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: gallery[i],
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: const Icon(Icons.image_not_supported, color: AppColors.grey),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SmoothPageIndicator(
            controller: controller,
            count: gallery.length,
            effect: ScrollingDotsEffect(
              activeDotColor: AppColors.primary,
              dotColor: AppColors.grey.withValues(alpha: 0.4),
              dotHeight: 8,
              dotWidth: 8,
              activeDotScale: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Description ───────────────────────────────────────────────────────────────

class _DescriptionSection extends StatelessWidget {
  final String description;
  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: AppColors.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Features ──────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final List<ProjectFeature> features;
  const _FeaturesSection({required this.features});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Features & Highlights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...features.map((f) => _FeatureCard(feature: f)),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final ProjectFeature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images carousel
          if (feature.images.isNotEmpty)
            _FeatureImageCarousel(images: feature.images),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (feature.title.isNotEmpty) ...[
                  Text(
                    feature.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (feature.subtitle.isNotEmpty)
                  Text(
                    feature.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.onBackground,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureImageCarousel extends StatefulWidget {
  final List<String> images;
  const _FeatureImageCarousel({required this.images});

  @override
  State<_FeatureImageCarousel> createState() => _FeatureImageCarouselState();
}

class _FeatureImageCarouselState extends State<_FeatureImageCarousel> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (_) => setState(() {}),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, _) => Container(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  child: const Icon(Icons.image_not_supported, color: AppColors.grey),
                ),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          SmoothPageIndicator(
            controller: _controller,
            count: widget.images.length,
            effect: ScrollingDotsEffect(
              activeDotColor: AppColors.primary,
              dotColor: AppColors.grey.withValues(alpha: 0.35),
              dotHeight: 6,
              dotWidth: 6,
              activeDotScale: 1.4,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}
