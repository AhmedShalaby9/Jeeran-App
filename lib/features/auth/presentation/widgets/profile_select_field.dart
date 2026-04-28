import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileSelectField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const ProfileSelectField({
    super.key,
    this.value,
    this.placeholder = 'Select',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  fontSize: 16,
                  color: value != null ? AppColors.ink : AppColors.inkMute,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.inkSub),
          ],
        ),
      ),
    );
  }
}
