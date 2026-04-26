import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../news/presentation/widgets/news_carousel_widget.dart';
import '../../../projects/presentation/widgets/explore_projects_widget.dart';
import '../widgets/banners_carousel_widget.dart';
import '../widgets/home_greeting_widget.dart';
import '../widgets/home_search_bar_widget.dart';
import '../widgets/home_sliver_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                const HomeSearchBarWidget(),
                const SizedBox(height: 16),
                const BannersCarouselWidget(),
                const SizedBox(height: 8),
                const ExploreProjectsWidget(),
                const SizedBox(height: 8),
                const NewsCarouselWidget(),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Featured Properties'),
                const SizedBox(height: 12),
                _FeaturedPropertiesRow(),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Nearby Listings'),
                const SizedBox(height: 12),
                ..._buildPropertyCards(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPropertyCards() {
    return List.generate(
      4,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _PropertyCard(index: i),
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

class _FeaturedPropertiesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, i) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _FeaturedCard(index: i),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final int index;
  const _FeaturedCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.apartment,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Amman, Jordan',
                  style: TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final int index;
  const _PropertyCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
            child: Center(
              child: Icon(
                index % 2 == 0 ? Icons.villa : Icons.apartment,
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    index % 2 == 0 ? 'Villa for Sale' : 'Apartment for Rent',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: AppColors.grey),
                      const SizedBox(width: 3),
                      Text(
                        'Amman, Jordan',
                        style: TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JOD ${(index + 1) * 35000}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.favorite_border, color: AppColors.grey, size: 20),
          ),
        ],
      ),
    );
  }
}
