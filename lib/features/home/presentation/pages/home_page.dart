import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../news/presentation/widgets/news_carousel_widget.dart';
import '../../../projects/presentation/widgets/explore_projects_widget.dart';
import '../../../properties/presentation/widgets/featured_properties_widget.dart';
import '../widgets/banners_carousel_widget.dart';
import '../widgets/home_greeting_widget.dart';
import '../widgets/home_search_bar_widget.dart';
import '../widgets/home_sliver_app_bar.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onSearchTap;
  const HomePage({super.key, this.onSearchTap});

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
                const SizedBox(height: 8),
                const ExploreProjectsWidget(),
                const SizedBox(height: 8),
                const NewsCarouselWidget(),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Featured Properties'),
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
  const _SectionTitle({required this.title});

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
          onPressed: () {},
          child: Text('See all', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}


