import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../projects/presentation/pages/project_details_page.dart';
import '../../domain/entities/notification_item.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../bloc/unread_count_cubit.dart';
import '../widgets/notif_helpers.dart';
import '../widgets/notification_tile.dart';
import '../widgets/notifications_empty.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationBloc>()..add(const LoadNotifications()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  void _onTap(BuildContext context, NotificationItem item) {
    context.read<NotificationBloc>().add(MarkNotificationRead(item.id));
    sl<UnreadCountCubit>().decrement();
    _navigate(context, item.notification);
  }

  void _navigate(BuildContext context, NotificationData notif) {
    switch (notif.type) {
      case 'project':
        if (notif.entityId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailsPage.fromId(
                projectId: notif.entityId,
                displayName: null,
              ),
            ),
          );
          return;
        }
      default:
        break;
    }
    // For all other types, stay on this page (content is already visible)
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final hasUnread = state is NotificationLoaded &&
            state.items.any((n) => !n.isRead);

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
              if (hasUnread)
                TextButton(
                  onPressed: () {
                    context
                        .read<NotificationBloc>()
                        .add(const MarkAllNotificationsRead());
                    sl<UnreadCountCubit>().reset();
                  },
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
          body: switch (state) {
            NotificationLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            NotificationError(message: final msg) => _ErrorView(
                message: msg,
                onRetry: () => context
                    .read<NotificationBloc>()
                    .add(const LoadNotifications()),
              ),
            NotificationLoaded(items: final items) when items.isEmpty =>
              const NotificationsEmpty(),
            NotificationLoaded(items: final items, hasMore: final hasMore) =>
              _GroupedList(
                items: items,
                hasMore: hasMore,
                onTap: (item) => _onTap(context, item),
                onLoadMore: () => context
                    .read<NotificationBloc>()
                    .add(const LoadMoreNotifications()),
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

// ── Grouped list ─────────────────────────────────────────────────────────────

class _GroupedList extends StatefulWidget {
  final List<NotificationItem> items;
  final bool hasMore;
  final void Function(NotificationItem) onTap;
  final VoidCallback onLoadMore;

  const _GroupedList({
    required this.items,
    required this.hasMore,
    required this.onTap,
    required this.onLoadMore,
  });

  @override
  State<_GroupedList> createState() => _GroupedListState();
}

class _GroupedListState extends State<_GroupedList> {
  static const _typeOrder = ['property', 'news', 'ad', 'project', 'subscription', 'general'];
  final Map<String, bool> _expanded = {};
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        widget.hasMore) {
      widget.onLoadMore();
    }
  }

  Map<String, List<NotificationItem>> get _grouped {
    final map = <String, List<NotificationItem>>{};
    for (final item in widget.items) {
      map.putIfAbsent(item.notification.type, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final grouped = _grouped;
    final sortedTypes = grouped.keys.toList()
      ..sort((a, b) {
        final ia = _typeOrder.indexOf(a);
        final ib = _typeOrder.indexOf(b);
        return (ia < 0 ? 999 : ia).compareTo(ib < 0 ? 999 : ib);
      });

    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sortedTypes.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.tagNeutralBg),
      itemBuilder: (context, i) {
        if (i == sortedTypes.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        final type = sortedTypes[i];
        final notifications = grouped[type]!;
        final isExpanded = _expanded[type] ?? true;
        return _NotificationSection(
          type: type,
          notifications: notifications,
          lang: lang,
          isExpanded: isExpanded,
          onToggle: () => setState(() => _expanded[type] = !isExpanded),
          onTap: widget.onTap,
        );
      },
    );
  }
}

// ── Section widget ────────────────────────────────────────────────────────────

class _NotificationSection extends StatelessWidget {
  final String type;
  final List<NotificationItem> notifications;
  final String lang;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(NotificationItem) onTap;

  const _NotificationSection({
    required this.type,
    required this.notifications,
    required this.lang,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMute,
                      ),
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
            ...notifications.map(
              (n) => NotificationTile(
                item: n,
                lang: lang,
                onTap: () => onTap(n),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSub, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('actions.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
