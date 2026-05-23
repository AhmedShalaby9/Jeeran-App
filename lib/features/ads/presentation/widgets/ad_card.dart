import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/ad.dart';
import '../pages/ad_details_page.dart';

class AdCard extends StatelessWidget {
  final Ad ad;
  const AdCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AdDetailsPage.push(context, ad),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              _buildImage(),

              // Gradient overlay — same stops as news card
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Bottom text — same layout as news card
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ad.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                        ),
                      ),
                      if (ad.name.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ad.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (ad.coverImage == null || !_isValidUrl(ad.coverImage!)) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.campaign_outlined, color: AppColors.primary, size: 40),
        ),
      );
    }
    return AppImage.network(ad.coverImage!, fit: BoxFit.cover);
  }

  static bool _isValidUrl(String url) =>
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));
}
