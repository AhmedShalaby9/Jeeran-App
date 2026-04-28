import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileFieldWrapper extends StatelessWidget {
  final String label;
  final bool required;
  final String? helper;
  final Widget child;

  const ProfileFieldWrapper({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: 0.1,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(helper!, style: const TextStyle(fontSize: 11, color: AppColors.inkMute, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
