import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../widgets/notif_item.dart';
import '../widgets/notification_section.dart';
import '../widgets/notifications_empty.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<NotifItem> _items = [
    NotifItem(
      title: 'New listing in Maadi',
      body: 'A 3-bedroom apartment has just been listed in Maadi starting at 2.5M EGP.',
      type: 'property',
      timeAgo: '2 minutes ago',
      isRead: false,
    ),
    NotifItem(
      title: 'Price drop: Zamalek apartment',
      body: 'The asking price for a Zamalek unit was reduced by 10%.',
      type: 'property',
      timeAgo: '1 hour ago',
      isRead: true,
    ),
    NotifItem(
      title: 'Market report Q1 2026',
      body: 'The latest real-estate market report for Q1 2026 is now available.',
      type: 'news',
      timeAgo: '3 hours ago',
      isRead: false,
    ),
    NotifItem(
      title: 'New regulations for foreign buyers',
      body: 'Egypt updates property ownership rules for non-residents.',
      type: 'news',
      timeAgo: 'Yesterday',
      isRead: true,
    ),
    NotifItem(
      title: 'Exclusive developer offer',
      body: 'Get 5% off on selected units this weekend only.',
      type: 'ads',
      timeAgo: '30 minutes ago',
      isRead: false,
    ),
    NotifItem(
      title: 'Zed East Phase 2 launched',
      body: 'New residential units in Zed East are now open for reservation.',
      type: 'project',
      timeAgo: '2 days ago',
      isRead: false,
    ),
    NotifItem(
      title: 'Hyde Park new units available',
      body: 'Hyde Park announces the release of 50 new townhouse units.',
      type: 'project',
      timeAgo: '3 days ago',
      isRead: true,
    ),
  ];

  static const _typeOrder = ['property', 'news', 'ads', 'project', 'general'];

  bool get _hasUnread => _items.any((n) => !n.isRead);

  Map<String, List<NotifItem>> get _grouped {
    final map = <String, List<NotifItem>>{};
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

  void _onTap(NotifItem item) {
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
      backgroundColor: AppColors.background,
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
          ? const NotificationsEmpty()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: sortedTypes.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.tagNeutralBg),
              itemBuilder: (context, i) {
                final type = sortedTypes[i];
                final notifications = grouped[type]!;
                final isExpanded = _expanded[type] ?? true;
                return NotificationSection(
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
