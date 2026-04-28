import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : const Color(0xFFD5DAE2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [const BoxShadow(color: Color(0x380B2A4A), blurRadius: 16, offset: Offset(0, 6))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.white : AppColors.inkMute,
            ),
          ),
        ),
      ),
    );
  }
}
