import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'notif_helpers.dart';
import 'notif_item.dart';

class NotificationTile extends StatelessWidget {
  final NotifItem item;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unread ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: unread
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.navButtonBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconForType(item.type),
                    size: 18,
                    color: unread ? AppColors.primary : AppColors.inkMute,
                  ),
                ),
                if (unread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                      color: unread ? AppColors.ink : AppColors.inkSub,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkMute,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.timeAgo,
                    style: const TextStyle(fontSize: 11, color: AppColors.inkMute),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
