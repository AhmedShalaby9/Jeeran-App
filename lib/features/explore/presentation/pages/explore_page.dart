import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../news/presentation/pages/all_news_page.dart';
import '../../../projects/presentation/pages/projects_page.dart';
import '../../../properties/domain/entities/property_filter_params.dart';
import '../../../properties/presentation/pages/properties_screen.dart';
import '../../../seller_request/presentation/bloc/seller_request_bloc.dart';
import '../../../seller_request/presentation/bloc/seller_request_event.dart';
import '../../../seller_request/presentation/bloc/seller_request_state.dart';
import '../../data/models/explore_data.dart';
import '../bloc/explore_cubit.dart';
import '../widgets/explore_banners.dart';
import '../widgets/explore_cards.dart';
import '../widgets/explore_widgets.dart';

/// Explore — the v2 home. Everything comes from one `GET /home` call.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExploreCubit>()..load(),
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatelessWidget {
  const _ExploreView();

  void _openFiltered(BuildContext context, PropertyFilterParams params) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PropertiesScreen(params: params)),
    );
  }

  Future<void> _showRejected(
    BuildContext context,
    SellerRequestStatus request,
  ) async {
    final resubmitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JV2.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _RejectedSheet(reason: request.rejectionReason),
    );
    if (resubmitted == true && context.mounted)
      context.read<ExploreCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreCubit, ExploreState>(
      builder: (context, state) {
        final cubit = context.read<ExploreCubit>();
        final data = state.data;

        return Column(
          children: [
            ExploreTopBar(area: state.area, onAreaChanged: cubit.setArea),
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
    final seller = d.sellerRequest;
    final showSeller =
        seller != null && (seller.isPending || seller.isRejected);

    final tiles = [
      QuickTile(
        labelKey: 'explore.chalets',
        count: d.typeCounts['chalet'] ?? 0,
        tint: const Color(0x381A4A80),
        onTap: () =>
            _openFiltered(context, const PropertyFilterParams(type: 'chalet')),
      ),
      QuickTile(
        labelKey: 'explore.villas',
        count: d.typeCounts['villa'] ?? 0,
        tint: const Color(0x42B8893D),
        onTap: () =>
            _openFiltered(context, const PropertyFilterParams(type: 'villa')),
      ),
      QuickTile(
        labelKey: 'explore.apartments',
        count: d.typeCounts['apartment'] ?? 0,
        tint: const Color(0x3312395F),
        onTap: () => _openFiltered(
          context,
          const PropertyFilterParams(type: 'apartment'),
        ),
      ),
      QuickTile(
        labelKey: 'explore.for_rent',
        count: d.statusCounts['for_rent'] ?? 0,
        tint: const Color(0x2E137A55),
        onTap: () => _openFiltered(
          context,
          const PropertyFilterParams(status: 'for_rent'),
        ),
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
      ),
      if (d.topBanners.isNotEmpty) BannerRail(banners: d.topBanners),
      if (showSeller)
        SellerStatusRow(
          request: seller,
          onRejectedTap: () => _showRejected(context, seller),
        ),
      QuickGrid(tiles: tiles),
      if (d.launches.isNotEmpty)
        section([
          SectionHead(
            eyebrow: 'explore.primary'.tr(),
            title: 'explore.new_launches'.tr(),
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectsPage()),
            ),
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
              MaterialPageRoute(builder: (_) => const AllNewsPage()),
            ),
          ),
          NewsRail(news: d.news),
        ]),
    ];

    return ListView.separated(
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
class _RejectedSheet extends StatefulWidget {
  final String? reason;
  const _RejectedSheet({this.reason});

  @override
  State<_RejectedSheet> createState() => _RejectedSheetState();
}

class _RejectedSheetState extends State<_RejectedSheet> {
  late final SellerRequestBloc _bloc = sl<SellerRequestBloc>();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = (widget.reason ?? '').trim();
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<SellerRequestBloc, SellerRequestState>(
        listener: (context, state) {
          if (state is SellerRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('explore.seller_resubmitted'.tr())),
            );
            Navigator.pop(context, true);
          } else if (state is SellerRequestError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final loading = state is SellerRequestLoading;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: JV2.track,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'explore.seller_rejected_dialog'.tr(),
                    style: JV2.display(context, 24),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x14C23B3B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      reason.isEmpty ? 'explore.seller_no_reason'.tr() : reason,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  JV2PrimaryButton(
                    onPressed: loading
                        ? null
                        : () => context.read<SellerRequestBloc>().add(
                            const SubmitSellerRequestEvent(),
                          ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text('explore.seller_resubmit'.tr()),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'explore.close'.tr(),
                        style: const TextStyle(
                          color: JV2.inkSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
