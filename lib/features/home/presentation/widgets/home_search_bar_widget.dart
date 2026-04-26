import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class HomeSearchBarWidget extends StatelessWidget {
  const HomeSearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
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
                'بحث',
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
