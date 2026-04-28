import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class PlanFeatureItem extends StatelessWidget {
  final String feature;
  final bool selected;

  const PlanFeatureItem({
    super.key,
    required this.feature,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 9,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
