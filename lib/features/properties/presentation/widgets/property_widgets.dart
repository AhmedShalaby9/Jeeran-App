import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const GlassButton({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.35),
      ),
      child: Center(child: child),
    ),
  );
}

class StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const StatPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    ),
  );
}

class InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const InfoChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.inkSub,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}

class ContactCircle extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const ContactCircle({super.key, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 16, color: Colors.white),
    ),
  );
}

class SquareButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const SquareButton({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline, width: 1.5),
      ),
      child: Center(child: child),
    ),
  );
}

class CTAButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const CTAButton({super.key, required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

class SimilarPropertyCard extends StatelessWidget {
  final Property property;
  const SimilarPropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 192,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (property.coverImage != null)
                  CachedNetworkImage(
                    imageUrl: property.coverImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const PropertyPlaceholder(),
                    errorWidget: (_, _, _) => const PropertyPlaceholder(),
                  )
                else
                  const PropertyPlaceholder(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.32),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (property.bedrooms != null)
                      _MiniSpec(icon: Icons.bed_rounded, value: ''),
                    if (property.bathrooms != null) ...[
                      const SizedBox(width: 8),
                      _MiniSpec(icon: Icons.bathtub_rounded, value: ''),
                    ],
                    if (property.size?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      _MiniSpec(icon: Icons.crop_square_rounded, value: property.size!),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  property.price ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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

class _MiniSpec extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MiniSpec({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 10, color: AppColors.inkSub),
      const SizedBox(width: 3),
      Text(value, style: const TextStyle(fontSize: 10, color: AppColors.inkSub)),
    ],
  );
}

class PropertyPlaceholder extends StatelessWidget {
  const PropertyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primary.withValues(alpha: 0.08),
    child: const Center(
      child: Icon(Icons.apartment, size: 40, color: AppColors.primary),
    ),
  );
}
