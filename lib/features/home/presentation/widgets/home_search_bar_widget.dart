import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';

class HomeSearchBarWidget extends StatelessWidget {
  final VoidCallback? onTap;
  const HomeSearchBarWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.grey, size: 22),
            Expanded(
              child: Text(
                'home.search_hint'.tr(),
                textAlign: TextAlign.end,
                style: TextStyle(color: AppColors.grey, fontSize: 15),
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.search_rounded, color: AppColors.grey, size: 24),
          ],
        ),
      ),
    );
  }
}
