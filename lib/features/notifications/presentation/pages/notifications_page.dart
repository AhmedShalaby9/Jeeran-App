import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<_NotifItem> _items = [
    _NotifItem(
      title: 'New listing in Maadi',
      body: 'A 3-bedroom apartment has just been listed in Maadi starting at 2.5M EGP.',
      type: 'property',
      timeAgo: '2 minutes ago',
      isRead: false,
    ),
    _NotifItem(
      title: 'Price drop: Zamalek apartment',
      body: 'The asking price for a Zamalek unit was reduced by 10%.',
      type: 'property',
      timeAgo: '1 hour ago',
      isRead: true,
    ),
    _NotifItem(
      title: 'Market report Q1 2026',
      body: 'The latest real-estate market report for Q1 2026 is now available.',
      type: 'news',
      timeAgo: '3 hours ago',
      isRead: false,
    ),
    _NotifItem(
      title: 'New regulations for foreign buyers',
      body: 'Egypt updates property ownership rules for non-residents.',
      type: 'news',
      timeAgo: 'Yesterday',
      isRead: true,
    ),
    _NotifItem(
      title: 'Exclusive developer offer',
      body: 'Get 5% off on selected units this weekend only.',
      type: 'ads',
      timeAgo: '30 minutes ago',
      isRead: false,
    ),
    _NotifItem(
      title: 'Zed East Phase 2 launched',
      body: 'New residential units in Zed East are now open for reservation.',
      type: 'project',
      timeAgo: '2 days ago',
      isRead: false,
    ),
    _NotifItem(
      title: 'Hyde Park new units available',
      body: 'Hyde Park announces the release of 50 new townhouse units.',
      type: 'project',
      timeAgo: '3 days ago',
      isRead: true,
    ),
  ];

  static const _typeOrder = ['property', 'news', 'ads', 'project', 'general'];

  bool get _hasUnread => _items.any((n) => !n.isRead);

  Map<String, List<_NotifItem>> get _grouped {
    final map = <String, List<_NotifItem>>{};
    for (final item in _items) {
      map.putIfAbsent(item.type, () => []).add(item);
    }
    return map;
  }

  final Map<String, bool> _expanded = {};

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item.isRead = true;
      }
    });
  }

  void _onTap(_NotifItem item) {
    // ignore: avoid_print
    print('Notification tapped: ${item.title}');
    if (!item.isRead) {
      setState(() => item.isRead = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final sortedTypes = grouped.keys.toList()
      ..sort((a, b) {
        final ia = _typeOrder.indexOf(a);
        final ib = _typeOrder.indexOf(b);
        return (ia < 0 ? 999 : ia).compareTo(ib < 0 ? 999 : ib);
      });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        actions: [
          if (_hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _items.isEmpty
          ? _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: sortedTypes.length,
              separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFFEEF0F4)),
              itemBuilder: (context, i) {
                final type = sortedTypes[i];
                final notifications = grouped[type]!;
                final isExpanded = _expanded[type] ?? true;
                return _NotificationSection(
                  type: type,
                  notifications: notifications,
                  isExpanded: isExpanded,
                  onToggle: () => setState(() => _expanded[type] = !isExpanded),
                  onTap: _onTap,
                );
              },
            ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

IconData _iconForType(String type) => switch (type) {
      'property' => Icons.home_outlined,
      'news' => Icons.article_outlined,
      'ads' => Icons.campaign_outlined,
      'project' => Icons.business_outlined,
      _ => Icons.notifications_outlined,
    };

String _labelForType(String type) => switch (type) {
      'property' => 'Properties',
      'news' => 'News',
      'ads' => 'Promotions',
      'project' => 'Projects',
      _ => 'General',
    };

// ── Section ───────────────────────────────────────────────────

class _NotificationSection extends StatelessWidget {
  final String type;
  final List<_NotifItem> notifications;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(_NotifItem) onTap;

  const _NotificationSection({
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
                  Icon(_iconForType(type), size: 20, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 10),
                  Text(
                    _labelForType(type),
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
                      color: const Color(0xFFEEF0F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${notifications.length}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            ...notifications.map((n) => _NotificationTile(item: n, onTap: () => onTap(n))),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

}

// ── Tile ──────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final _NotifItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

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
            color: unread
                ? AppColors.primary.withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
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
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    size: 18,
                    color: unread ? AppColors.primary : const Color(0xFF9CA3AF),
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

// ── Empty state ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
}

// ── Model ─────────────────────────────────────────────────────

class _NotifItem {
  final String title;
  final String body;
  final String type;
  final String timeAgo;
  bool isRead;

  _NotifItem({
    required this.title,
    required this.body,
    required this.type,
    required this.timeAgo,
    required this.isRead,
  });
}
