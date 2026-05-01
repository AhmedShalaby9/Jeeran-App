import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';

class ChatHistoryHeader extends StatelessWidget {
  final VoidCallback onNewChat;
  const ChatHistoryHeader({super.key, required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.headerGradientEnd],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              _AiAvatarCircle(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ai_chat.jeeran_ai'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'ai_chat.chat_history'.tr(),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_note_rounded,
                      color: Colors.white, size: 22),
                  tooltip: 'ai_chat.new_chat'.tr(),
                  onPressed: onNewChat,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiAvatarCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: 22),
    );
  }
}
