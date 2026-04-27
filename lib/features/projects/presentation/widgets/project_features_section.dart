import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/project.dart';

class ProjectFeaturesSection extends StatelessWidget {
  final List<ProjectFeature> features;
  const ProjectFeaturesSection({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'project_details.features'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...features.map((f) => ProjectFeatureCard(feature: f)),
      ],
    );
  }
}

class ProjectFeatureCard extends StatelessWidget {
  final ProjectFeature feature;
  const ProjectFeatureCard({super.key, required this.feature});

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
          if (feature.images.isNotEmpty)
            ProjectFeatureImageCarousel(images: feature.images),
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

class ProjectFeatureImageCarousel extends StatefulWidget {
  final List<String> images;
  const ProjectFeatureImageCarousel({super.key, required this.images});

  @override
  State<ProjectFeatureImageCarousel> createState() => _ProjectFeatureImageCarouselState();
}

class _ProjectFeatureImageCarouselState extends State<ProjectFeatureImageCarousel> {
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
