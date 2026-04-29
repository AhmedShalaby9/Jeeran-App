import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../../core/widgets/lazy_indexed_stack.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../properties/presentation/pages/add_property_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../projects/presentation/pages/projects_page.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../more/presentation/pages/more_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final _searchResetNotifier = ValueNotifier<bool>(false);

  static final List<_NavItem> _navItems = [
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

  void _goToProjects() {
    if (_selectedIndex == 2) return;
    setState(() => _selectedIndex = 2);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onSearchTap: _goToProjects),
      SearchPage(resetNotifier: _searchResetNotifier),
      const ProjectsPage(),
      const FavoritesPage(),
      const MorePage(),
    ];
  }

  @override
  void dispose() {
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
      child: _MainScaffold(
        selectedIndex: _selectedIndex,
        pages: _pages,
        navItems: _navItems,
        onTap: _onItemTapped,
        onAddListing: AppStorage.isSeller
            ? () => AddPropertyPage.push(context)
            : null,
      ),
    );
  }
}


class _MainScaffold extends StatelessWidget {
  final int selectedIndex;
  final List<Widget> pages;
  final List<_NavItem> navItems;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddListing;

  const _MainScaffold({
    required this.selectedIndex,
    required this.pages,
    required this.navItems,
    required this.onTap,
    this.onAddListing,
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
      floatingActionButton: onAddListing != null
          ? _AddListingFab(onTap: onAddListing!)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _AddListingFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddListingFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
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
            color: Colors.black.withValues(alpha: 0.08),
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
                        ? AppColors.primary.withValues(alpha: 0.1)
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
