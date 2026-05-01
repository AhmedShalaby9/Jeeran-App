import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';

class ChatEmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  const ChatEmptyState({super.key, required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.secondary, AppColors.secondaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'ai_chat.no_conversations'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ai_chat.no_conversations_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.inkMute, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'ai_chat.start_new_chat'.tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
