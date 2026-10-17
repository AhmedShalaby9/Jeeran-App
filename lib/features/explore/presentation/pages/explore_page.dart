import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../voice/voice_page.dart';
import '../../../news/v2/news_list_page.dart';
import 'all_compounds_page.dart';
import '../../../developers/presentation/pages/developer_page.dart';
import '../../../search/presentation/widgets/search_widgets.dart'
    show DevRailCard;
import '../../../search/presentation/all_developers_page.dart';
import '../../../../core/network/api_client.dart';
import '../../../search/presentation/launches_page.dart';
import '../../../search/presentation/promotion_page.dart';
import '../../../search/data/search_api.dart';
import '../../../listing/shortcut_hub.dart';
import '../../../../core/storage/app_storage.dart';
import '../../data/models/explore_data.dart';
import '../bloc/explore_cubit.dart';
import '../widgets/explore_banners.dart';
import '../widgets/explore_cards.dart';
import '../widgets/explore_widgets.dart';

/// Explore — the v2 home. Everything comes from one `GET /home` call.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  /// Bumped when the Home tab is tapped while Home is already showing: the feed scrolls back to the top.
  static final scrollToTop = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExploreCubit>()..load(),
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ExplorePage.scrollToTop.addListener(_toTop);
  }

  @override
  void dispose() {
    ExplorePage.scrollToTop.removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (!_scroll.hasClients || _scroll.offset <= 0) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  /// "See all" on New launches: every live launch and offer, with the All / Launches / Offers tabs.
  /// Tapping one shows its units in the Search tab.
  void _openAllCompounds(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AllCompoundsPage(api: SearchApi(sl<ApiClient>())),
    ),
  );

  void _openDeveloper(BuildContext context, DeveloperSummary d) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DeveloperPage(developerId: d.id, name: d.name(isArabic(context))),
        ),
      );

  void _openAllDevelopers(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AllDevelopersPage(
        api: SearchApi(sl<ApiClient>()),
        onOpen: (d) => _openDeveloper(context, d),
      ),
    ),
  );

  void _openLaunches(BuildContext context, {int tab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => LaunchesPage(
          initialTab: tab,
          api: SearchApi(sl<ApiClient>()),
          // a launch or offer opens its own page, over the list so Back returns to it
          onOpen: (p) => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) =>
                  PromotionPage(item: p, api: SearchApi(sl<ApiClient>())),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreCubit, ExploreState>(
      builder: (context, state) {
        final cubit = context.read<ExploreCubit>();
        final data = state.data;

        return Column(
          children: [
            ExploreTopBar(
              // "Do it": list a property, change a price
              onShortcut:
                  AppStorage.isLoggedIn &&
                      AppStorage.canList &&
                      !AppSettingsService.instance.inReview
                  ? () => ShortcutHub.open(context)
                  : null,
            ),
            Expanded(
              child: data == null
                  ? (state.status == ExploreStatus.failure
                        ? _ErrorState(onRetry: cubit.load)
                        : const _ExploreSkeleton())
                  : RefreshIndicator(
                      color: JV2.navy,
                      onRefresh: cubit.load,
                      child: _buildFeed(context, data),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeed(BuildContext context, ExploreData d) {
    // "browse by who and where": totals are real, not estimates
    int n(String k) => d.counts[k] ?? 0;
    final tiles = [
      QuickTile(
        labelKey: 'explore.q_compounds',
        subKey: 'explore.q_compounds_n',
        count: n('compounds_total'),
        tint: const Color(0x381A4A80),
        onTap: () => _openAllCompounds(context),
      ),
      QuickTile(
        labelKey: 'explore.q_developers',
        subKey: 'explore.q_developers_n',
        count: n('developers_total'),
        tint: const Color(0x42B8893D),
        onTap: () => _openAllDevelopers(context),
      ),
      QuickTile(
        labelKey: 'explore.q_launches',
        subKey: 'explore.q_launches_n',
        count: n('launches_total'),
        tint: const Color(0x3312395F),
        onTap: () => _openLaunches(context, tab: 1),
      ),
      QuickTile(
        labelKey: 'explore.q_offers',
        subKey: 'explore.q_offers_n',
        count: n('offers_total'),
        tint: const Color(0x2E137A55),
        onTap: () => _openLaunches(context, tab: 2),
      ),
    ];

    Widget section(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    final blocks = <Widget>[
      const ExploreGreeting(),
      ExploreSearchEntry(
        onSearch: () => MainPage.switchTab(MainPage.tabSearch),
        onAsk: AppSettingsService.instance.inReview
            ? null
            : () => MainPage.switchTab(MainPage.tabAsk),
        onVoice: AppSettingsService.instance.inReview
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoicePage()),
              ),
      ),
      if (d.topBanners.isNotEmpty) BannerRail(banners: d.topBanners),
      QuickGrid(tiles: tiles),
      if (d.launches.isNotEmpty)
        section([
          SectionHead(
            eyebrow: 'explore.primary'.tr(),
            title: 'explore.new_launches'.tr(),
            onAction: () => _openLaunches(context),
          ),
          LaunchStrip(projects: d.launches),
        ]),
      if (d.featured.isNotEmpty)
        section([
          SectionHead(
            eyebrow: 'explore.handpicked'.tr(),
            title: 'explore.featured_for_you'.tr(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final p in d.featured)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ExplorePropertyCard(property: p),
                  ),
              ],
            ),
          ),
        ]),
      // the second banner placement: one in-feed slot, never a stack
      if (d.feedBanner != null) InFeedBanner(banner: d.feedBanner!),
      if (d.news.isNotEmpty)
        section([
          SectionHead(
            eyebrow: 'explore.market'.tr(),
            title: 'explore.latest_news'.tr(),
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsListPage()),
            ),
          ),
          NewsRail(news: d.news),
        ]),
      if (d.topDevelopers.isNotEmpty)
        section([
          SectionHead(
            eyebrow: 'explore.devs_eyebrow'.tr(),
            title: 'explore.top_developers'.tr(),
            onAction: () => _openAllDevelopers(context),
          ),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: d.topDevelopers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 11),
              itemBuilder: (_, i) => DevRailCard(
                d: d.topDevelopers[i],
                onTap: () => _openDeveloper(context, d.topDevelopers[i]),
              ),
            ),
          ),
        ]),
      if (d.topCompounds.isNotEmpty)
        section([
          SectionHead(
            eyebrow:
                (d.topIsByViews
                        ? 'explore.top_eyebrow'
                        : 'explore.top_eyebrow_units')
                    .tr(),
            title: 'explore.top_compounds'.tr(),
            onAction: () => _openAllCompounds(context),
          ),
          TopCompoundsRail(projects: d.topCompounds),
        ]),
    ];

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, bottom: 30),
      itemCount: blocks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 26),
      itemBuilder: (_, i) => blocks[i],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 46),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: JV2.inkMute),
            const SizedBox(height: 14),
            Text(
              'explore.load_failed'.tr(),
              textAlign: TextAlign.center,
              style: JV2.display(context, 22),
            ),
            const SizedBox(height: 18),
            JV2PrimaryButton(
              width: 160,
              height: 46,
              onPressed: onRetry,
              child: Text('explore.try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  Widget _box(double h, {double? w, double r = 16}) => Container(
    height: h,
    width: w,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9EEF4),
      highlightColor: const Color(0xFFF6F8FB),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        children: [
          _box(14, w: 140, r: 6),
          const SizedBox(height: 10),
          _box(56, w: 220, r: 10),
          const SizedBox(height: 22),
          _box(50, r: 15),
          const SizedBox(height: 26),
          _box(158, w: 286, r: 18),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: _box(74, r: 15)),
              const SizedBox(width: 10),
              Expanded(child: _box(74, r: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _box(74, r: 15)),
              const SizedBox(width: 10),
              Expanded(child: _box(74, r: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Why the request was rejected, with the way back in.
