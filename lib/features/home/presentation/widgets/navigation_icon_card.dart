import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

Widget buildNavigationCard({required String title, required IconData icon, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.tagPrimaryBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    ),
  );
}
