import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';

class ChatLoadError extends StatelessWidget {
  final String message;
  const ChatLoadError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.grey, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.inkMute, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text('ai_chat.go_back'.tr()),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSendErrorBanner extends StatelessWidget {
  final String message;
  const ChatSendErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.danger.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
