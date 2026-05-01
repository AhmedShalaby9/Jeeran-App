import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../domain/entities/chat_session.dart';

class ChatSessionCard extends StatelessWidget {
  final ChatSession session;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChatSessionCard({
    super.key,
    required this.session,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ai_chat.just_now'.tr();
    if (diff.inHours < 1) {
      return 'ai_chat.minutes_ago'
          .tr(namedArgs: {'count': diff.inMinutes.toString()});
    }
    if (diff.inDays < 1) {
      return 'ai_chat.hours_ago'
          .tr(namedArgs: {'count': diff.inHours.toString()});
    }
    if (diff.inDays == 1) return 'ai_chat.yesterday'.tr();
    if (diff.inDays < 7) {
      return 'ai_chat.days_ago'
          .tr(namedArgs: {'count': diff.inDays.toString()});
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: isDeleting ? 0.45 : 1.0,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.hardEdge,
          elevation: 1.5,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: isDeleting ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Row(
                children: [
                  _SessionAvatar(isDeleting: isDeleting),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(session.updatedAt),
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5, top: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              'ai_chat.tap_to_continue'.tr(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.inkMute,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isDeleting) ChatSessionMenuButton(onDelete: onDelete),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Session avatar ─────────────────────────────────────────────────────────────
class _SessionAvatar extends StatelessWidget {
  final bool isDeleting;
  const _SessionAvatar({required this.isDeleting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.secondaryDark],
        ),
      ),
      child: isDeleting
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 20),
    );
  }
}

// ── Popup menu button ─────────────────────────────────────────────────────────
class ChatSessionMenuButton extends StatelessWidget {
  final VoidCallback onDelete;
  const ChatSessionMenuButton({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.inkMute, size: 20),
      color: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 8),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 20),
              const SizedBox(width: 10),
              Text(
                'actions.delete'.tr(),
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
