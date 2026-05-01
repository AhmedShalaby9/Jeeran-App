import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/news.dart';
import '../bloc/news_bloc.dart';
import '../bloc/news_state.dart';
import '../pages/all_news_page.dart';
import '../pages/news_details_page.dart';

class NewsCarouselWidget extends StatelessWidget {
  const NewsCarouselWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NewsCarouselView();
  }
}

class _NewsCarouselView extends StatefulWidget {
  const _NewsCarouselView();

  @override
  State<_NewsCarouselView> createState() => _NewsCarouselViewState();
}

class _NewsCarouselViewState extends State<_NewsCarouselView> {
  final _pageController = PageController(viewportFraction: 0.88);
  Timer? _autoSwipeTimer;
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients || _itemCount == 0) return;
      final next = (_pageController.page!.round() + 1) % _itemCount;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsBloc, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading) {
          return SizedBox(height: 200, child: Center(child: AppLoading.cupertino()));
        }
        if (state is NewsLoaded && state.news.isNotEmpty) {
          return _buildContent(context, state.news);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, List<News> news) {
    final displayNews = news.take(5).toList();
    _itemCount = displayNews.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'news.title'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllNewsPage())),
              child: Text('news.show_all'.tr(), style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: displayNews.length,
            onPageChanged: (index) => setState(() {}),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _NewsCard(news: displayNews[i]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SmoothPageIndicator(
            controller: _pageController,
            count: displayNews.length,
            effect: ExpandingDotsEffect(
              dotHeight: 6,
              dotWidth: 6,
              expansionFactor: 4,
              spacing: 6,
              activeDotColor: AppColors.primary,
              dotColor: AppColors.grey.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final News news;
  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailsPage(news: news))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMedia(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        news.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            news.publishedAt.isNotEmpty ? news.publishedAt.substring(0, 10) : '',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final firstMedia = news.coverMedia;
    if (firstMedia == null || !_isValidUrl(firstMedia)) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Center(child: Icon(Icons.article, color: AppColors.primary, size: 40)),
      );
    }
    if (_isVideoUrl(firstMedia)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.videocam, color: AppColors.primary, size: 40),
          ),
          const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
        ],
      );
    }
    return AppImage.network(firstMedia, fit: BoxFit.cover);
  }

  static bool _isVideoUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  static bool _isValidUrl(String url) {
    return url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
  }
}
