import 'package:easy_localization/easy_localization.dart';
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
import '../../../follow/presentation/follow_pill.dart';
import '../../data/developer_page_data.dart';

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
      if (mounted) setState(() => _data = DeveloperPageData.fromJson(raw));
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
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: JV2.navy)),
          )
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
                AskContextCard(scope: AskScope(AskScopeType.developer, d.id, d.name.pick(_ar))),
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
              Positioned(
                top: top + 8,
                left: 16,
                right: 16,
                child: const Row(children: [PhotoBackButton()]),
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
                Container(
                  width: 72,
                  height: 72,
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: JV2.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: JV2.line, width: 1),
                    boxShadow: JV2.shadowMd,
                  ),
                  child: (d?.logo ?? '').isNotEmpty
                      ? Photo(url: d!.logo, width: 72, height: 72, radius: 20)
                      : Text(
                          name.isEmpty
                              ? '?'
                              : name.characters.first.toUpperCase(),
                          style: JV2
                              .display(context, 30)
                              .copyWith(color: JV2.navy),
                        ),
                ),
                const Spacer(),
                if (d != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: FollowButton(type: FollowType.developer, id: d.id),
                  ),
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
    if (desc.isEmpty && rows.isEmpty && d.trustItems.isEmpty) {
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
      ],
    );
  }

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
      'developer.n_units'.plural(c.unitsCount),
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
