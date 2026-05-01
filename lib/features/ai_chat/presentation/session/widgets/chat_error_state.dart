import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';

class ChatErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ChatErrorState(
      {super.key, required this.message, required this.onRetry});

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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('actions.retry'.tr()),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
