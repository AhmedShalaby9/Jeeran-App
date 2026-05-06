import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../ai_chat/presentation/session/pages/ai_chat_history_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../../core/widgets/lazy_indexed_stack.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../projects/presentation/pages/projects_page.dart';
import '../../../more/presentation/pages/more_page.dart';
import 'tab4_destination.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static final _tabNotifier = ValueNotifier<int?>(null);

  /// Switch to the given tab index from anywhere in the app.
  static void switchTab(int index) => _tabNotifier.value = index;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool _isSeller = AppStorage.isSeller;
  bool _hasSubscription = false;
  late List<Widget> _pages;
  late List<_NavItem> _navItems;
  final _searchResetNotifier = ValueNotifier<bool>(false);

  void _goToProjects() {
    if (_selectedIndex == 2) return;
    setState(() => _selectedIndex = 2);
  }

  void _buildNav() {
    _pages = [
      HomePage(onSearchTap: _goToProjects),
      SearchPage(resetNotifier: _searchResetNotifier),
      const ProjectsPage(),
      Tab4Destination.create(isSeller: _isSeller),
      const MorePage(),
    ];

    _navItems = [
      _NavItem(
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        label: 'bottom_nav.home'.tr(),
      ),
      _NavItem(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: 'bottom_nav.search'.tr(),
      ),
      _NavItem(
        icon: Icons.business_outlined,
        activeIcon: Icons.business,
        label: 'bottom_nav.projects'.tr(),
      ),
      if (_isSeller)
        _NavItem(
          icon: Icons.workspace_premium_outlined,
          activeIcon: Icons.workspace_premium,
          label: _hasSubscription
              ? 'subscription.title'.tr()
              : 'bottom_nav.packages'.tr(),
        )
      else
        _NavItem(
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          label: 'bottom_nav.favorites'.tr(),
        ),
      _NavItem(
        icon: Icons.more_horiz,
        activeIcon: Icons.more_horiz,
        label: 'bottom_nav.more'.tr(),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _buildNav();
    MainPage._tabNotifier.addListener(_onTabSwitch);
  }

  void _onTabSwitch() {
    final index = MainPage._tabNotifier.value;
    if (index != null && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      MainPage._tabNotifier.value = null;
    }
  }

  void _onAuthUpdated(bool isSeller, bool hasSubscription) {
    if (_isSeller == isSeller && _hasSubscription == hasSubscription) return;
    setState(() {
      final roleChanged = _isSeller != isSeller;
      _isSeller = isSeller;
      _hasSubscription = hasSubscription;
      if (roleChanged) _selectedIndex = 0;
      _buildNav();
    });
  }

  @override
  void dispose() {
    MainPage._tabNotifier.removeListener(_onTabSwitch);
    _searchResetNotifier.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
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
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthMeLoaded) {
            _onAuthUpdated(state.user.isSeller, state.user.subscriptionId != null);
          }
        },
        child: _MainScaffold(
          selectedIndex: _selectedIndex,
          pages: _pages,
          navItems: _navItems,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class _MainScaffold extends StatelessWidget {
  final int selectedIndex;
  final List<Widget> pages;
  final List<_NavItem> navItems;
  final ValueChanged<int> onTap;

  const _MainScaffold({
    required this.selectedIndex,
    required this.pages,
    required this.navItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LazyIndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: _JeeranBottomNavBar(
        selectedIndex: selectedIndex,
        items: navItems,
        onTap: onTap,
      ),
      floatingActionButton: const _AiChatFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _AiChatFab extends StatefulWidget {
  const _AiChatFab();

  @override
  State<_AiChatFab> createState() => _AiChatFabState();
}

class _AiChatFabState extends State<_AiChatFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary
                    .withValues(alpha: 0.25 + 0.25 * _pulse.value),
                blurRadius: 18 + 10 * _pulse.value,
                spreadRadius: 2 + 2 * _pulse.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const AiChatHistoryPage(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        tooltip: 'Jeeran AI',
        shape: const CircleBorder(),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

class _JeeranBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _JeeranBottomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == selectedIndex;
              final item = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 24,
                        color: selected ? AppColors.primary : AppColors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected ? AppColors.primary : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
