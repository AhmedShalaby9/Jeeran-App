import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/jv2.dart';

class ProfileTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType type;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const ProfileTextInput({
    super.key,
    required this.controller,
    required this.hint,
    this.type = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    // no fixed height: the vertical padding sets the box, so the hint and the text sit exactly in the middle
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: TextField(
        controller: controller,
        keyboardType: type,
        onChanged: onChanged,
        readOnly: readOnly,
        enabled: !readOnly,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: 16,
          color: readOnly ? AppColors.inkSub : AppColors.ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.inkMute, fontSize: 16),
          filled: true,
          fillColor: readOnly ? JV2.fillHi : JV2.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: JV2.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: JV2.line),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: JV2.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: JV2.navy, width: 1.5),
          ),
        ),
      ),
    );
  }
}
