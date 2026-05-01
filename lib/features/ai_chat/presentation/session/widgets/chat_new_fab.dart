import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';

class ChatNewFab extends StatelessWidget {
  final VoidCallback onTap;
  const ChatNewFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(
        'ai_chat.new_chat'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}
