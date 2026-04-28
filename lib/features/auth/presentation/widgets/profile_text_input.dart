import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType type;
  final ValueChanged<String>? onChanged;

  const ProfileTextInput({
    super.key,
    required this.controller,
    required this.hint,
    this.type = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        keyboardType: type,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.inkMute, fontSize: 16),
          filled: true,
          fillColor: const Color(0xFFF5F6F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.hairline, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.hairline, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
