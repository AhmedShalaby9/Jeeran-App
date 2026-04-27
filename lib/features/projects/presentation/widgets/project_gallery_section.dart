import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/utils/app_colors.dart';

class ProjectGallerySection extends StatelessWidget {
  final List<String> gallery;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const ProjectGallerySection({
    super.key,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'project_details.gallery'.tr(),
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
