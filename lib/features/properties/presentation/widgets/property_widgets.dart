import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

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
  final Widget icon;
  final VoidCallback onTap;
  const ContactCircle({super.key, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(child: icon),
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
  final Widget icon;
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
          icon,
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
