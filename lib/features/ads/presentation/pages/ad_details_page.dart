import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/ad.dart';

class AdDetailsPage extends StatelessWidget {
  final Ad ad;

  const AdDetailsPage({super.key, required this.ad});

  static void push(BuildContext context, Ad ad) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdDetailsPage(ad: ad)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _AdSliverAppBar(ad: ad),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    ad.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),

                  if (ad.name.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 16, color: AppColors.inkSub),
                        const SizedBox(width: 6),
                        Text(
                          ad.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.inkSub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (ad.description != null && ad.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    Text(
                      ad.description!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.inkSub,
                        height: 1.7,
                      ),
                    ),
                  ],

                  // Image gallery (remaining images after cover)
                  if (ad.images.length > 1) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Gallery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GalleryGrid(images: ad.images.skip(1).toList()),
                  ],

                  // Contact buttons
                  if (ad.phoneNumber != null || ad.whatsappNumber != null) ...[
                    const SizedBox(height: 28),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ContactButtons(ad: ad),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sliver app bar with cover image ──────────────────────────────────────────

class _AdSliverAppBar extends StatelessWidget {
  final Ad ad;
  const _AdSliverAppBar({required this.ad});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: ad.coverImage != null
            ? CachedNetworkImage(
                imageUrl: ad.coverImage!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Center(child: AppLoading.cupertino()),
                errorWidget: (_, _, _) => _imageFallback(),
              )
            : _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.campaign_outlined, size: 64, color: AppColors.primary),
        ),
      );
}

// ── Gallery grid ─────────────────────────────────────────────────────────────

class _GalleryGrid extends StatelessWidget {
  final List<String> images;
  const _GalleryGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _showFullImage(context, images[i]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: images[i],
            fit: BoxFit.cover,
            placeholder: (_, _) => Center(child: AppLoading.cupertino()),
            errorWidget: (_, _, _) => Container(
              color: AppColors.primary.withValues(alpha: 0.08),
              child: const Icon(Icons.image_not_supported_outlined, color: AppColors.grey),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact buttons ───────────────────────────────────────────────────────────

class _ContactButtons extends StatelessWidget {
  final Ad ad;
  const _ContactButtons({required this.ad});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (ad.phoneNumber != null)
          _ContactChip(
            icon: Icons.phone_outlined,
            label: 'Call',
            color: AppColors.primary,
            onTap: () => _launch('tel:${ad.phoneNumber}'),
          ),
        if (ad.whatsappNumber != null)
          _ContactChip(
            icon: Icons.chat_outlined,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => _launch('https://wa.me/${ad.whatsappNumber!.replaceAll(RegExp(r'\D'), '')}'),
          ),
      ],
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
