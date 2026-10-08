import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../ai_chat/ask/ask_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import '../../../../core/widgets/lazy_indexed_stack.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../packages/presentation/pages/packages_destination.dart';
import '../../../compounds/presentation/pages/compound_page.dart';
import '../../../developers/presentation/pages/developer_page.dart';
import '../../../search/presentation/search_home.dart';
import '../../../more/presentation/pages/more_page.dart';
import '../main_badges.dart';

/// The five fixed tabs. They never rearrange when a buyer becomes a seller —
/// seller tools live inside You.
enum MainTab { explore, search, ask, saved, you }

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  // Legacy int indices (the old call sites use these): same order as [MainTab].
  static const int tabExplore = 0;
  static const int tabSearch = 1;
  static const int tabAsk = 2;
  static const int tabSaved = 3;
  static const int tabYou = 4;

  static final _tabNotifier = ValueNotifier<MainTab?>(null);

  /// Switch tab from anywhere in the app. Ignored if that tab isn't shown
  /// (Ask is hidden while the store build is in review).
  static void switchTab(int index) {
    if (index < 0 || index >= MainTab.values.length) return;
    _tabNotifier.value = MainTab.values[index];
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late List<MainTab> _tabs;
  late List<Widget> _pages;
  int _selectedIndex = 0;
  final _searchResetNotifier = ValueNotifier<bool>(false);
  StreamSubscription<Map<String, dynamic>>? _fcmTapSub;
  StreamSubscription<Map<String, dynamic>>? _fcmFgSub;
  StreamSubscription<FavoritesState>? _favSub;

  bool get _inReview => AppSettingsService.instance.inReview;

  Widget _pageFor(MainTab t) => switch (t) {
    MainTab.explore => const ExplorePage(),
    MainTab.search => SearchHome(resetNotifier: _searchResetNotifier),
    MainTab.ask => const AskView(),
    MainTab.saved => const SavedPage(),
    MainTab.you => const MorePage(),
  };

  void _buildTabs() {
    _tabs = [
      for (final t in MainTab.values)
        if (t != MainTab.ask || !_inReview) t,
    ];
    _pages = [for (final t in _tabs) _pageFor(t)];
  }

  @override
  void initState() {
    super.initState();
    _buildTabs();
    MainPage._tabNotifier.addListener(_onTabSwitch);
    sl<UnreadCountCubit>().fetch();

    // Keep the Saved badge honest as the user saves / unsaves.
    _favSub = sl<FavoritesBloc>().stream.listen((s) {
      if (s is FavoritesLoaded)
        MainBadges.savedCount.value = s.properties.length;
    });

    _fcmTapSub = NotificationService.instance.tapStream.listen(_handleFcmTap);
    _fcmFgSub = NotificationService.instance.foregroundStream.listen((_) {
      sl<UnreadCountCubit>().increment();
    });
  }

  void _handleFcmTap(Map<String, dynamic> data) {
    if (!mounted) return;
    final type = data['type'] as String? ?? 'general';
    final entityId = int.tryParse(data['entity_id'] as String? ?? '');

    switch (type) {
      case 'developer':
        if (entityId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeveloperPage(developerId: entityId),
            ),
          );
          return;
        }
      case 'project' || 'compound':
        if (entityId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompoundPage(compoundId: entityId, name: null),
            ),
          );
          return;
        }
      case 'subscription':
        // Plans & billing used to be a seller-only tab; it now opens from You.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PackagesDestination()),
        );
        return;
      default:
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _onTabSwitch() {
    final tab = MainPage._tabNotifier.value;
    if (tab == null) return;
    MainPage._tabNotifier.value = null;
    final index = _tabs.indexOf(tab);
    if (index != -1 && index != _selectedIndex)
      setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    MainPage._tabNotifier.removeListener(_onTabSwitch);
    _searchResetNotifier.dispose();
    _fcmTapSub?.cancel();
    _fcmFgSub?.cancel();
    _favSub?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    if (_tabs[index] == MainTab.saved)
      SavedPage.reload.value++; // always show fresh prices
    _searchResetNotifier.value = !_searchResetNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthGetMeEvent()),
        ),
        BlocProvider.value(value: sl<FavoritesBloc>()),
        BlocProvider.value(value: sl<UnreadCountCubit>()),
      ],
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: LazyIndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: _JeeranTabBar(
          tabs: _tabs,
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// ── Notification bell — drop into any page's AppBar.actions ─────────────────

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnreadCountCubit, int>(
      builder: (context, count) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: AppColors.onBackground,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ).then((_) => sl<UnreadCountCubit>().fetch()),
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Tab bar (v2): Explore · Search · Ask · Saved · You ──────────────────────

class _JeeranTabBar extends StatelessWidget {
  final List<MainTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _JeeranTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  static String _label(MainTab t) => 'bottom_nav.${t.name}'.tr();

  static IconData _icon(MainTab t, bool on) => switch (t) {
    MainTab.explore => on ? Icons.home_rounded : Icons.home_outlined,
    MainTab.search => Icons.search_rounded,
    MainTab.ask => Icons.auto_awesome_rounded,
    MainTab.saved =>
      on ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
    MainTab.you => on ? Icons.person_rounded : Icons.person_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xDBFFFFFF), // .86
            border: Border(top: BorderSide(color: JV2.line)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _TabItem(
                        tab: tabs[i],
                        label: _label(tabs[i]),
                        icon: _icon(tabs[i], i == selectedIndex),
                        selected: i == selectedIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final MainTab tab;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hero = tab == MainTab.ask;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 34, child: hero ? _askPill() : _glyph()),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.1,
              color: selected ? JV2.navy : JV2.inkSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _askPill() {
    return Center(
      child: Container(
        width: 46,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: LinearGradient(
            begin: const Alignment(-0.5, -1),
            end: const Alignment(0.5, 1),
            colors: selected
                ? const [JV2.navyLift, JV2.navy]
                : const [JV2.navy, Color(0xFF071D34)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(selected ? 0x570B2A4A : 0x380B2A4A),
              blurRadius: selected ? 20 : 12,
              offset: Offset(0, selected ? 8 : 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 19,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _glyph() {
    final color = selected ? JV2.navy : JV2.inkMute;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 24, color: color),
        if (tab == MainTab.saved)
          ValueListenableBuilder<int>(
            valueListenable: MainBadges.savedCount,
            builder: (_, n, _) => n <= 0
                ? const SizedBox.shrink()
                : Positioned(
                    top: 2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: JV2.goldHi,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        n > 99 ? '99+' : '$n',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        if (tab == MainTab.you)
          ValueListenableBuilder<bool>(
            valueListenable: MainBadges.youAttention,
            builder: (_, on, _) => !on
                ? const SizedBox.shrink()
                : Positioned(
                    top: 5,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: JV2.goldHi,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
          ),
        if (selected)
          Positioned(
            bottom: -3,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: JV2.goldHi,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ── FCM token unregistration helper (called from logout) ────────────────────

Future<void> unregisterFcmTokenOnLogout() async {
  try {
    final info = DeviceInfoPlugin();
    final String deviceId;
    if (Platform.isAndroid) {
      deviceId = (await info.androidInfo).id;
    } else {
      deviceId = (await info.iosInfo).identifierForVendor ?? '';
    }
    if (deviceId.isNotEmpty) {
      await sl<NotificationRepository>().unregisterFcmToken(deviceId);
    }
  } catch (_) {}
}
