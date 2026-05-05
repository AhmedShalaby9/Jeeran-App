import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'notif_helpers.dart';
import 'notif_item.dart';
import 'notification_tile.dart';

class NotificationSection extends StatelessWidget {
  final String type;
  final List<NotifItem> notifications;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(NotifItem) onTap;

  const NotificationSection({
    super.key,
    required this.type,
    required this.notifications,
    required this.isExpanded,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(iconForType(type), size: 20, color: AppColors.inkSub),
                  const SizedBox(width: 10),
                  Text(
                    labelForType(type),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tagNeutralBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${notifications.length}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMute),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: AppColors.inkMute,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            ...notifications.map((n) => NotificationTile(item: n, onTap: () => onTap(n))),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
