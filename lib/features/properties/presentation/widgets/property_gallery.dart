import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/app_colors.dart';
import 'property_widgets.dart';

class PropertyGallery extends StatelessWidget {
  final List<String> images;
  final int photoIdx;
  final bool saved;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;
  final VoidCallback onBack;

  const PropertyGallery({
    super.key,
    required this.images,
    required this.photoIdx,
    required this.saved,
    required this.pageController,
    required this.onPageChanged,
    required this.onToggleSave,
    required this.onShare,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (images.isNotEmpty)
          PageView.builder(
            controller: pageController,
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, _) => const PropertyPlaceholder(),
              errorWidget: (_, _, _) => const PropertyPlaceholder(),
            ),
          )
        else
          const PropertyPlaceholder(),
        // Frosted top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 54, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassButton(
                  onTap: onBack,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    GlassButton(
                      onTap: onShare,
                      child: const Icon(
                        Icons.share_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassButton(
                      onTap: onToggleSave,
                      child: Icon(
                        saved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: saved ? AppColors.dangerPink : Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Dot indicator
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == photoIdx;
                return GestureDetector(
                  onTap: () => pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
