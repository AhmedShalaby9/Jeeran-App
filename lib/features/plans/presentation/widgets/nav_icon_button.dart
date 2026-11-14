import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart' show backArrowIcon;

class NavIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const NavIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.navButtonBg,
        ),
        child: Icon(
          backArrowIcon(context),
          size: 16,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
