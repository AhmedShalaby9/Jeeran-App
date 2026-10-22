import 'package:easy_localization/easy_localization.dart';
import '../../../compounds/presentation/widgets/compound_units.dart'
    show LogoTile, TopBadge;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../ai_chat/scoped/ask_context.dart';
import '../../../ai_chat/scoped/ask_scope_api.dart';
import '../../../compounds/presentation/pages/compound_page.dart';
import '../../../compounds/presentation/widgets/page_widgets.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../../follow/data/follow_service.dart';
import '../../../follow/presentation/follow_alerts.dart';
import '../../../news/v2/news_api.dart';
import '../../../news/v2/news_article_page.dart';
import '../../../news/v2/news_widgets.dart';
import '../../../units/presentation/unit_widgets.dart' show UnitSecHead;
import '../../data/developer_page_data.dart';
import '../widgets/developer_shimmer.dart';

/// A developer's page: cover + logo + Follow, key figures, then Compounds / Listings / About.
/// "Call us" dials the number saved in the dashboard settings — there is no messaging.
class DeveloperPage extends StatefulWidget {
  final int developerId;
  final String? name; // shown while loading

  const DeveloperPage({super.key, required this.developerId, this.name});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  DeveloperPageData? _data;
  bool _failed = false;
  int _tab = 0;
  FollowController? _follow; // created once the developer has loaded
  late final _newsApi = NewsApi(sl<ApiClient>());
  List<NewsItem> _news = []; // loaded after the developer itself; empty just means none yet (or none linked)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final res = await sl<ApiClient>().get(
        ApiEndpoints.developerById(widget.developerId),
        headers: ApiClient.apiV2,
      );
      final raw = res.data['data'];
      if (raw is! Map<String, dynamic>) throw const FormatException();
      if (mounted) {
        final data = DeveloperPageData.fromJson(raw);
        setState(() {
          _data = data;
          _follow = FollowController(
            service: sl<FollowService>(),
            type: FollowType.developer,
            id: data.id,
            name: data.name.pick(_ar),
            following: data.isFollowing,
            alertsOn: data.alertsOn,
            events: data.alertEvents,
          );
        });
        // a supplementary section: never blocks or fails the page itself. The server rolls a developer's
        // own compounds' news into this too, so a story tagged to one compound still shows up here.
        _newsApi.list(developerId: data.id).then((n) {
          if (mounted) setState(() => _news = n);
        }).catchError((_) {});
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  bool get _ar => isArabic(context);

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: _failed
            ? Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 10,
                      20,
                      8,
                    ),
                    child: const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: JV2BackButton(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'explore.load_failed'.tr(),
                            style: JV2.display(context, 22),
                          ),
                          const SizedBox(height: 16),
                          JV2PrimaryButton(
                            width: 160,
                            height: 46,
                            onPressed: _load,
                            child: Text('explore.try_again'.tr()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(child: _content(d)),
                  if (d != null) CallBar(label: 'developer.call_us'.tr()),
                ],
              ),
      ),
    );
  }

  Widget _content(DeveloperPageData? d) {
    final name = d == null ? (widget.name ?? '') : d.name.pick(_ar);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _hero(d, name),
        if (d == null)
          const DeveloperBodyShimmer()
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatStrip([
                  ('${d.compoundsCount}', 'developer.stat_compounds'.tr()),
                  ('${d.unitsCount}', 'developer.stat_listings'.tr()),
                  if (d.deliveredUnits != null)
                    (
                      compactPrice(d.deliveredUnits!.toDouble()),
                      'developer.stat_delivered'.tr(),
                    ),
                ]),
                const SizedBox(height: 16),
                AskContextCard(
                  scope: AskScope(
                    AskScopeType.developer,
                    d.id,
                    d.name.pick(_ar),
                  ),
                ),
                if (d.unitsCount == 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    key: const Key('dev-no-units'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: JV2.fillFaint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: JV2.line),
                    ),
                    child: Text(
                      'unit.dev_no_units'.tr(
                        namedArgs: {'name': d.name.pick(_ar)},
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                ],
                if (_follow != null) ...[
                  const SizedBox(height: 16),
                  AlertsStrip(c: _follow!),
                ],
                const SizedBox(height: 20),
                PageTabs(
                  labels: [
                    'developer.tab_compounds'.tr(),
                    'developer.tab_listings'.tr(),
                    'developer.tab_about'.tr(),
                  ],
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 18),
                switch (_tab) {
                  0 => _compounds(d),
                  1 => LiveListings(
                    key: ValueKey('dev-${d.id}'),
                    query: {'developer_id': d.id},
                    emptyText: 'developer.listings_empty'.tr(),
                  ),
                  _ => _about(d),
                },
              ],
            ),
          ),
      ],
    );
  }

  Widget _hero(DeveloperPageData? d, String name) {
    final top = MediaQuery.of(context).padding.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Photo(url: d?.cover, radius: 0),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.42, 1],
                    colors: [
                      Color(0x470B2A4A),
                      Color(0x00000000),
                      Color(0xEBFAFBFD),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: top + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    const PhotoBackButton(),
                    const Spacer(),
                    if (_follow != null) HeroBell(c: _follow!),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Transform.translate(
            offset: const Offset(0, -28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LogoTile(name: name, logo: d?.logo, size: 72),
                if (_follow != null) ...[
                  const SizedBox(width: 13),
                  Expanded(child: FollowCta(c: _follow!, height: 44)),
                ],
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: JV2.display(context, 31)),
                if (d != null) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (d.isVerified) ...[
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: JV2.success,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'developer.verified'.tr(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: JV2.success,
                          ),
                        ),
                        const Text(
                          '  ·  ',
                          style: TextStyle(color: JV2.inkMute),
                        ),
                      ],
                      if (d.isTop) ...[
                        const TopBadge(),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        'developer.followers'.plural(d.followersCount),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: JV2.inkSub,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _compounds(DeveloperPageData d) {
    if (d.compounds.isEmpty) {
      return EmptyBlock(
        icon: Icons.apartment_rounded,
        title: 'developer.compounds_empty'.tr(),
      );
    }
    return Column(
      children: [
        for (final c in d.compounds)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CompoundRow(c),
          ),
      ],
    );
  }

  Widget _about(DeveloperPageData d) {
    final desc = d.desc.pick(_ar);
    final rows = <(String, String)>[
      if (d.headOffice != null) ('developer.head_office'.tr(), d.headOffice!),
      if (d.foundedYear != null) ('developer.founded'.tr(), '${d.foundedYear}'),
      if (d.stockListing != null) ('developer.listed_on'.tr(), d.stockListing!),
    ];
    if (desc.isEmpty && rows.isEmpty && d.trustItems.isEmpty && _news.isEmpty) {
      return EmptyBlock(
        icon: Icons.info_outline_rounded,
        title: 'developer.no_about'.tr(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desc.isNotEmpty) ...[
          Text(desc, style: JV2.sub),
          const SizedBox(height: 22),
        ],
        if (d.trustItems.isNotEmpty) ...[
          _trust(d.trustItems),
          const SizedBox(height: 22),
        ],
        for (final r in rows) InfoRow(r.$1, r.$2),
        if (_news.isNotEmpty) ...[
          if (desc.isNotEmpty || rows.isNotEmpty || d.trustItems.isNotEmpty) const SizedBox(height: 24),
          UnitSecHead('developer.related_news'.tr()),
          const SizedBox(height: 12),
          for (var i = 0; i < _news.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            NewsRow(item: _news[i], onTap: () => _openNews(_news[i])),
          ],
        ],
      ],
    );
  }

  void _openNews(NewsItem item) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NewsArticlePage(item: item, api: _newsApi)),
  );

  /// "Why we list them" — only ever built for verified developers.
  Widget _trust(List<TrustItem> items) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JV2.goldFilm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JV2.goldEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: JV2.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'developer.why_title'.tr(),
                  style: JV2.display(context, 21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_rounded, size: 16, color: JV2.gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.title.pick(_ar).isNotEmpty)
                          Text(
                            t.title.pick(_ar),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: JV2.ink,
                            ),
                          ),
                        if (t.detail.pick(_ar).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              t.detail.pick(_ar),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: JV2.inkSub,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CompoundRow extends StatelessWidget {
  final DeveloperCompoundRow c;
  const _CompoundRow(this.c);

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final name = c.name.pick(ar);
    final meta = <String>[
      if (c.area.pick(ar).isNotEmpty) c.area.pick(ar),
      c.unitsCount == 0
          ? 'unit.no_units_yet'.tr()
          : 'developer.n_units'.plural(c.unitsCount),
    ].join(' · ');
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompoundPage(compoundId: c.id, name: name),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JV2.line),
        ),
        child: Row(
          children: [
            Photo(url: c.image, width: 82, height: 82, radius: 13),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (CompoundStatusChip.label(c.status) != null) ...[
                    CompoundStatusChip(c.status),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: JV2.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: const TextStyle(fontSize: 12, color: JV2.inkSub),
                  ),
                  if (c.minPrice != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${'explore.from_price'.tr(args: [compactPrice(c.minPrice!)])} ${'explore.egp'.tr()}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: JV2.navy,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(chevronIcon(context), size: 18, color: JV2.inkMute),
          ],
        ),
      ),
    );
  }
}
