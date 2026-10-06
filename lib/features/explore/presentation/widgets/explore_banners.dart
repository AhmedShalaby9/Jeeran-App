import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../ai_ads/presentation/pages/ai_ads_page.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../news/presentation/pages/all_news_page.dart';
import '../../../projects/presentation/pages/project_details_page.dart';
import '../../../properties/data/models/property_model.dart';
import '../../../properties/presentation/pages/property_details_page.dart';
import '../../data/models/explore_data.dart';
import 'explore_widgets.dart';

/// Runs a banner's tap target. A target that can't be resolved is a silent no-op —
/// a banner should never crash the feed.
class BannerActions {
  BannerActions._();

  static Future<void> open(BuildContext context, ExploreBanner b) async {
    switch (b.targetType) {
      case 'url':
        final uri = Uri.tryParse(b.link ?? '');
        if (uri != null)
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      case 'phone':
        if ((b.phone ?? '').isNotEmpty)
          await launchUrl(Uri(scheme: 'tel', path: b.phone));
      case 'project':
        if (b.targetId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailsPage.fromId(
                projectId: b.targetId,
                displayName: null,
              ),
            ),
          );
        }
      case 'property':
        if (b.targetId != null) await _openProperty(context, b.targetId!);
      case 'news':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AllNewsPage()),
        );
      case 'ai_ads':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAdsPage()),
        );
      case 'seller_signup':
        MainPage.switchTab(
          MainPage.tabYou,
        ); // "Join us as a seller" lives in You
      default:
        break;
    }
  }

  static Future<void> _openProperty(BuildContext context, int id) async {
    try {
      final res = await sl<ApiClient>().get('/properties/$id');
      final data = res.data['data'];
      if (data is! Map<String, dynamic> || !context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PropertyDetailsPage(property: PropertyModel.fromJson(data)),
        ),
      );
    } catch (_) {}
  }
}

/// The creative itself: uploaded media, with the caption laid over it.
class BannerMedia extends StatelessWidget {
  final ExploreBanner banner;
  final double height;

  const BannerMedia({super.key, required this.banner, required this.height});

  @override
  Widget build(BuildContext context) {
    final arabic = isArabic(context);
    final caption = banner.caption(arabic);
    final sub = banner.sub(arabic);
    final sponsor = (banner.sponsorName ?? '').isNotEmpty
        ? banner.sponsorName!
        : null;

    return Photo(
      url: banner.imageUrl,
      height: height,
      radius: 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x470B2A4A),
                  Color(0x000B2A4A),
                  Color(0xB80B2A4A),
                ],
                stops: [0, 0.34, 1],
              ),
            ),
          ),
          if (banner.isVideo) _PlayBadge(duration: banner.durationLabel),
          if (banner.isSponsored)
            PositionedDirectional(
              top: 10,
              start: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xEBFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'explore.ad_by'.tr(args: [sponsor ?? '']).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: JV2.gold,
                  ),
                ),
              ),
            ),
          if (caption.isNotEmpty || sub.isNotEmpty)
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caption.isNotEmpty)
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: JV2
                          .display(context, 19)
                          .copyWith(
                            color: Colors.white,
                            height: 1.16,
                            shadows: const [
                              Shadow(
                                color: Color(0x730B2A4A),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xD1FFFFFF),
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x2EFFFFFF),
                          border: Border.all(color: const Color(0x47FFFFFF)),
                        ),
                        child: Icon(
                          chevronIcon(context),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  final String? duration;
  const _PlayBadge({this.duration});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x8C0B2A4A),
              border: Border.all(color: const Color(0x59FFFFFF)),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        if (duration != null)
          PositionedDirectional(
            bottom: 38,
            end: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x9E0B2A4A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                duration!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// explore_top: a snapping rail with a pager.
class BannerRail extends StatefulWidget {
  final List<ExploreBanner> banners;

  const BannerRail({super.key, required this.banners});

  @override
  State<BannerRail> createState() => _BannerRailState();
}

class _BannerRailState extends State<BannerRail> {
  static const double _cardW = 286;
  static const double _gap = 12;
  final _scroll = ScrollController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final i = (_scroll.offset / (_cardW + _gap)).round().clamp(
        0,
        widget.banners.length - 1,
      );
      if (i != _index) setState(() => _index = i);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.banners;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: _SnapPhysics(itemExtent: _cardW + _gap),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => BannerActions.open(context, items[i]),
              child: Container(
                width: _cardW,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E0B2A4A),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BannerMedia(banner: items[i], height: 158),
                ),
              ),
            ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var n = 0; n < items.length; n++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: n == _index ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: n == _index ? JV2.gold : const Color(0x330B2A4A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Settles on a card boundary after a fling (the rail's "scroll-snap: start").
class _SnapPhysics extends ScrollPhysics {
  final double itemExtent;
  const _SnapPhysics({required this.itemExtent, super.parent});

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  double _target(ScrollMetrics m, double velocity) {
    var page = m.pixels / itemExtent;
    if (velocity < -50) {
      page = page.floorToDouble();
    } else if (velocity > 50) {
      page = page.ceilToDouble();
    } else {
      page = page.roundToDouble();
    }
    return (page * itemExtent).clamp(m.minScrollExtent, m.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = _target(position, velocity);
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// explore_feed: one full-width slot, never a stack.
class InFeedBanner extends StatelessWidget {
  final ExploreBanner banner;

  const InFeedBanner({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => BannerActions.open(context, banner),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: JV2.line),
            boxShadow: JV2.shadowMd,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: BannerMedia(banner: banner, height: 172),
          ),
        ),
      ),
    );
  }
}
