import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

enum TagTone { gold, primary, success, neutral }

class TagChip extends StatelessWidget {
  final String label;
  final TagTone tone;

  const TagChip({
    super.key,
    required this.label,
    this.tone = TagTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      TagTone.gold => (AppColors.tagGoldBg, AppColors.tagGoldFg),
      TagTone.primary => (AppColors.tagPrimaryBg, AppColors.primary),
      TagTone.success => (AppColors.tagSuccessBg, AppColors.tagSuccessFg),
      TagTone.neutral => (AppColors.tagNeutralBg, AppColors.inkSub),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
