import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../v2/notif_actions.dart';
import '../../v2/notif_api.dart';
import '../bloc/unread_count_cubit.dart';
import 'notification_settings_page.dart';

const double _pad = 20;

/// The inbox: one chronological list, types as filter chips, newest first.
class NotificationsPage extends StatefulWidget {
  final NotifApi? api; // tests inject a fake
  const NotificationsPage({super.key, this.api});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotifApi _api = widget.api ?? NotifApi(sl<ApiClient>());
  final _scroll = ScrollController();

  static const _filters = <(String? key, String label)>[
    (null, 'notif.f_all'),
    ('listings', 'notif.f_listings'),
    ('projects', 'notif.f_projects'),
    ('plans', 'notif.f_plans'),
    ('news', 'notif.f_news'),
    ('ads', 'notif.f_ads'),
  ];

  String? _filter;
  List<InboxItem>? _items; // null = loading
  InboxSummary _summary = InboxSummary.empty;
  int _page = 1;
  int _pages = 1;
  bool _loadingMore = false;
  bool _failed = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 400) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final seq = ++_seq;
    setState(() {
      _items = null;
      _failed = false;
      _page = 1;
    });
    try {
      final results = await Future.wait([
        _api.list(filter: _filter),
        _api.summary(),
      ]);
      if (!mounted || seq != _seq) return;
      final page = results[0] as InboxPage;
      setState(() {
        _items = page.items;
        _pages = page.pages;
        _summary = results[1] as InboxSummary;
      });
      _syncBadge();
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items == null || _page >= _pages) return;
    final seq = _seq;
    setState(() => _loadingMore = true);
    try {
      final next = await _api.list(filter: _filter, page: _page + 1);
      if (!mounted || seq != _seq) return;
      setState(() {
        _items = [..._items!, ...next.items];
        _page += 1;
        _pages = next.pages;
      });
    } catch (_) {
      // the next scroll tries again
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Keeps the red dot on the tab bar and the bell in step with what this screen knows.
  void _syncBadge() {
    try {
      sl<UnreadCountCubit>().set(_summary.unread);
    } catch (_) {}
  }

  Future<void> _read(InboxItem n) async {
    if (n.isRead) return;
    setState(() {
      _items = [for (final x in _items!) x.id == n.id ? x.asRead() : x];
      _summary = _bump(_summary, n, -1);
    });
    _syncBadge();
    try {
      await _api.markRead(n.id);
    } catch (_) {
      // the server will say so on the next refresh; the user's tap is not worth an error
    }
  }

  /// Which filter chip an item counts toward.
  static String? _chipOf(String type) => switch (type) {
    'property' => 'listings',
    'project' || 'developer' => 'projects',
    'subscription' => 'plans',
    'news' => 'news',
    'ad' => 'ads',
    _ => null,
  };

  InboxSummary _bump(InboxSummary s, InboxItem n, int by) {
    final chip = _chipOf(n.type);
    final filters = {...s.filters};
    if (chip != null)
      filters[chip] = ((filters[chip] ?? 0) + by).clamp(0, 1 << 30);
    return InboxSummary((s.unread + by).clamp(0, 1 << 30), filters);
  }

  Future<void> _readAll() async {
    setState(() {
      _items = [for (final x in _items!) x.asRead()];
      _summary = InboxSummary(0, {for (final k in _summary.filters.keys) k: 0});
    });
    _syncBadge();
    try {
      await _api.markAllRead();
    } catch (_) {}
  }

  void _open(InboxItem n) {
    _read(n);
    final action = actionFor(n, ar: isArabic(context));
    action?.run(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          _header(),
          _chips(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _header() {
    final unread = _summary.unread;
    return Container(
      padding: EdgeInsets.fromLTRB(
        _pad,
        MediaQuery.of(context).padding.top + 8,
        _pad,
        14,
      ),
      decoration: const BoxDecoration(
        color: Color(0xE6FAFBFD),
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: JV2.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: JV2.line),
                  ),
                  child: Icon(
                    isRtl(context)
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 22,
                    color: JV2.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'notif.title'.tr(),
                  style: JV2.display(context, 22),
                ),
              ),
              if (unread > 0)
                GestureDetector(
                  onTap: _readAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: JV2.fillFaint,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: JV2.line),
                    ),
                    child: Text(
                      'notif.mark_all'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: JV2.navy,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                ),
                child: Tooltip(
                  message: 'notif.open_settings'.tr(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: JV2.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: JV2.line),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 19,
                      color: JV2.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          unread > 0
              ? Text(
                  'notif.unread_n'.plural(unread),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.gold,
                  ),
                )
              : Text(
                  'notif.caught_up'.tr(),
                  style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
                ),
        ],
      ),
    );
  }

  Widget _chips() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(_pad, 14, _pad, 4),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label) = _filters[i];
          final on = key == _filter;
          final count = key == null
              ? _summary.unread
              : (_summary.filters[key] ?? 0);
          return GestureDetector(
            onTap: () {
              if (key == _filter) return;
              setState(() => _filter = key);
              _reload();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: on ? JV2.navy : JV2.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? JV2.navy : JV2.line),
                boxShadow: on
                    ? const [
                        BoxShadow(
                          color: Color(0x330B2A4A),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    label.tr(),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                      color: on ? Colors.white : JV2.inkSub,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on ? const Color(0x38FFFFFF) : JV2.goldFilm,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: on ? Colors.white : JV2.gold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('notif.load_failed'.tr(), style: JV2.display(context, 20)),
            const SizedBox(height: 14),
            JV2PrimaryButton(
              width: 150,
              height: 44,
              onPressed: _reload,
              child: Text('notif.retry'.tr()),
            ),
          ],
        ),
      );
    }
    final items = _items;
    if (items == null)
      return const Center(child: CircularProgressIndicator(color: JV2.navy));
    if (items.isEmpty) return _empty();

    final groups = <String, List<InboxItem>>{};
    for (final n in items) {
      groups.putIfAbsent(_dayKey(n.createdAt), () => []).add(n);
    }
    return RefreshIndicator(
      color: JV2.navy,
      onRefresh: _reload,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(_pad - 6, 6, _pad - 6, 26),
        children: [
          for (final e in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
              child: Row(
                children: [
                  Text(
                    e.key.tr().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: JV2.inkMute,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Divider(height: 1, color: JV2.line)),
                ],
              ),
            ),
            for (final n in e.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _Row(n: n, onTap: () => _open(n)),
              ),
          ],
          if (_loadingMore || _page < _pages)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: JV2.goldHi,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty() {
    final filtered = _filter != null;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: JV2.fillFaint,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: JV2.line),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 27,
              color: JV2.inkSub,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52),
          child: Column(
            children: [
              Text(
                filtered
                    ? 'notif.filter_empty'.tr(
                        args: [
                          _filters.firstWhere((f) => f.$1 == _filter).$2.tr(),
                        ],
                      )
                    : 'notif.empty_title'.tr(),
                textAlign: TextAlign.center,
                style: JV2.display(context, 22),
              ),
              if (!filtered) ...[
                const SizedBox(height: 12),
                Text(
                  'notif.empty_sub'.tr(),
                  textAlign: TextAlign.center,
                  style: JV2.sub.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 18),
                JV2PrimaryButton(
                  width: 190,
                  height: 46,
                  onPressed: () {
                    Navigator.popUntil(context, (r) => r.isFirst);
                    MainPage.switchTab(MainPage.tabSearch);
                  },
                  child: Text('notif.browse'.tr()),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _dayKey(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    return diff <= 0
        ? 'notif.day_today'
        : (diff == 1 ? 'notif.day_yesterday' : 'notif.day_earlier');
  }
}

class _Row extends StatelessWidget {
  final InboxItem n;
  final VoidCallback onTap;
  const _Row({required this.n, required this.onTap});

  static (Color tint, Color ink, IconData icon) _look(String type) =>
      switch (type) {
        'property' => (const Color(0x1A1A4A80), JV2.navy, Icons.home_outlined),
        'project' || 'developer' => (
          const Color(0x1A137A55),
          JV2.success,
          Icons.apartment_rounded,
        ),
        'news' => (const Color(0x248A93A3), JV2.inkSub, Icons.article_outlined),
        'subscription' => (
          const Color(0x24B8893D),
          JV2.gold,
          Icons.credit_card_rounded,
        ),
        'ad' => (
          const Color(0x1A1A4A80),
          JV2.navyLift,
          Icons.auto_awesome_rounded,
        ),
        _ => (
          const Color(0x1F8A93A3),
          JV2.inkSub,
          Icons.notifications_none_rounded,
        ),
      };

  static String ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'notif.ago_now'.tr();
    if (d.inMinutes < 60) return 'notif.ago_m'.tr(args: ['${d.inMinutes}']);
    if (d.inHours < 24) return 'notif.ago_h'.tr(args: ['${d.inHours}']);
    if (d.inDays < 7) return 'notif.ago_d'.tr(args: ['${d.inDays}']);
    return 'notif.ago_w'.tr(args: ['${d.inDays ~/ 7}']);
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final (tint, ink, icon) = _look(n.type);
    final action = actionFor(n, ar: ar);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.transparent : JV2.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: n.isRead ? Colors.transparent : JV2.line),
          boxShadow: n.isRead
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0D0B2A4A),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: ink),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          n.title(ar),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: JV2.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ago(n.createdAt),
                        style: const TextStyle(fontSize: 11, color: JV2.inkSub),
                      ),
                      if (!n.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: JV2.goldHi,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body(ar),
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: JV2.inkSub,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 9),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action.labelKey.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(chevronIcon(context), size: 13, color: ink),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
