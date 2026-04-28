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
import '../widgets/home_subscription_card.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onSearchTap;
  const HomePage({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<BannersBloc>()..add(const FetchBannersEvent()),
        ),
        BlocProvider(
          create: (_) => sl<ProjectsBloc>()..add(const FetchProjectsEvent()),
        ),
        BlocProvider(
          create: (_) => sl<NewsBloc>()..add(const FetchNewsEvent()),
        ),
        BlocProvider(
          create: (_) => sl<PropertiesBloc>()
            ..add(
              const FetchPropertiesEvent(
                PropertyFilterParams(isFeatured: true, perPage: 10),
              ),
            ),
        ),
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

                const HomeSubscriptionCard(state: HomeSubscriptionState.unsubscribed),

                const SizedBox(height: 8),
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
                        builder: (_) => const PropertiesScreen(
                          params: PropertyFilterParams(isFeatured: true),
                        ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            'home.see_all'.tr(),
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
