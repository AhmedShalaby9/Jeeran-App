import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

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
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
