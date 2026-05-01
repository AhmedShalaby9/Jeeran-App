import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../news/presentation/bloc/news_bloc.dart';
import '../../../news/presentation/bloc/news_event.dart';
import '../../../news/presentation/widgets/news_carousel_widget.dart';
import '../../../projects/presentation/bloc/projects_bloc.dart';
import '../../../projects/presentation/bloc/projects_event.dart';
import '../../../projects/presentation/widgets/explore_projects_widget.dart';
import '../../../properties/domain/entities/property_filter_params.dart';
import '../../../properties/presentation/bloc/properties_bloc.dart';
import '../../../properties/presentation/bloc/properties_event.dart';
import '../../../properties/presentation/pages/properties_screen.dart';
import '../../../properties/presentation/widgets/featured_properties_widget.dart';
import '../bloc/banners_bloc.dart';
import '../bloc/banners_event.dart';
import '../widgets/banners_carousel_widget.dart';
import '../widgets/home_greeting_widget.dart';
import '../widgets/home_search_bar_widget.dart';
import '../widgets/home_sliver_app_bar.dart';
import '../widgets/navigation_cards_grid.dart';
import '../../../ai_chat/presentation/session/pages/ai_chat_history_page.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onSearchTap;
  const HomePage({super.key, this.onSearchTap});

  static bool _initialized = false;
  static late final PropertiesBloc _propertiesBloc;

  void _ensureEventsDispatched() {
    if (_initialized) return;
    _initialized = true;
    sl<BannersBloc>().add(const FetchBannersEvent());
    sl<ProjectsBloc>().add(const FetchProjectsEvent());
    sl<NewsBloc>().add(const FetchNewsEvent());
    _propertiesBloc = sl<PropertiesBloc>();
    _propertiesBloc.add(const FetchPropertiesEvent(PropertyFilterParams(isFeatured: true, perPage: 10)));
  }

  @override
  Widget build(BuildContext context) {
    _ensureEventsDispatched();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<BannersBloc>()),
        BlocProvider.value(value: sl<ProjectsBloc>()),
        BlocProvider.value(value: sl<NewsBloc>()),
        BlocProvider.value(value: _propertiesBloc),
      ],
      child: _HomeView(onSearchTap: onSearchTap),
    );
  }
}

class _HomeView extends StatelessWidget {
  final VoidCallback? onSearchTap;
  const _HomeView({this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _AiChatFab(),
      body: CustomScrollView(
        slivers: [
          const HomeSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const HomeGreetingWidget(),
                const SizedBox(height: 12),
                HomeSearchBarWidget(onTap: onSearchTap),
                const SizedBox(height: 16),
                const BannersCarouselWidget(),
                const SizedBox(height: 16),
                const NavigationCardsGrid(),

                const SizedBox(height: 16),

                // if (AppStorage.isSeller) ...[
                //   const HomeSubscriptionCard(
                //     state: HomeSubscriptionState.unsubscribed,
                //   ),
                //   const SizedBox(height: 8),
                // ],
                const ExploreProjectsWidget(),
                const SizedBox(height: 8),
                const NewsCarouselWidget(),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'home.featured_properties'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PropertiesScreen(params: PropertyFilterParams(isFeatured: true)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const FeaturedPropertiesWidget(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Chat FAB ───────────────────────────────────────────────────────────────
class _AiChatFab extends StatefulWidget {
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

// ── Section Title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _SectionTitle({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
        ),
        TextButton(
          onPressed: onTap,
          child: Text('home.see_all'.tr(), style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
