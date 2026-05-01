import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/app_banner.dart';
import '../bloc/banners_bloc.dart';
import '../bloc/banners_state.dart';

class BannersCarouselWidget extends StatelessWidget {
  const BannersCarouselWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BannersCarouselView();
  }
}

class _BannersCarouselView extends StatefulWidget {
  const _BannersCarouselView();

  @override
  State<_BannersCarouselView> createState() => _BannersCarouselViewState();
}

class _BannersCarouselViewState extends State<_BannersCarouselView> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  void _startAutoScroll(int count) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      _currentPage = (_currentPage + 1) % count;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BannersBloc, BannersState>(
      listener: (context, state) {
        if (state is BannersLoaded && state.banners.length > 1) {
          _startAutoScroll(state.banners.length);
        }
      },
      builder: (context, state) {
        if (state is BannersLoading) return _buildShimmer();
        if (state is BannersLoaded && state.banners.isNotEmpty) {
          return _buildCarousel(state.banners);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCarousel(List<AppBanner> banners) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _BannerItem(
                banner: banners[i],
                onContactTap: banners[i].hasPhone
                    ? () => _showContactSheet(context, banners[i].phone!)
                    : banners[i].hasLink
                        ? () => _openLink(banners[i].link!)
                        : null,
              ),
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 12),
            SmoothPageIndicator(
              controller: _pageController,
              count: banners.length,
              effect: WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                spacing: 6,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showContactSheet(BuildContext context, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: AppColors.primary),
                title: Text('home.phone_call'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(phone);
                },
              ),
              ListTile(
                leading: Icon(Icons.chat, color: Colors.green.shade600),
                title: Text('home.whatsapp'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _openWhatsApp(phone);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone) async {
    String clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!clean.startsWith('+')) clean = '+';
    final uri = Uri.parse('https://wa.me/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _BannerItem extends StatelessWidget {
  final AppBanner banner;
  final VoidCallback? onContactTap;
  const _BannerItem({required this.banner, this.onContactTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onContactTap,
        child: AppImage.network(
          banner.imageUrl,
          borderRadius: BorderRadius.circular(12),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
