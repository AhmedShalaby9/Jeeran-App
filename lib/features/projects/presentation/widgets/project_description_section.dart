import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class ProjectDescriptionSection extends StatelessWidget {
  final String description;
  const ProjectDescriptionSection({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: AppColors.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
