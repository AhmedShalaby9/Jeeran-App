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
import '../../../developers/presentation/pages/developer_page.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../../follow/data/follow_service.dart';
import '../../data/compound_page_data.dart';
import '../widgets/facility_icon.dart';
import '../widgets/page_widgets.dart';

/// A compound's page: gallery, key figures, then Units / Phases / About.
/// Following (the heart) turns on every notification for it. "Call to book a viewing"
/// dials the number saved in the dashboard settings.
class CompoundPage extends StatefulWidget {
  final int compoundId;
  final String? name; // shown while loading

  const CompoundPage({super.key, required this.compoundId, this.name});

  @override
  State<CompoundPage> createState() => _CompoundPageState();
}

class _CompoundPageState extends State<CompoundPage> {
  CompoundPageData? _data;
  bool _failed = false;
  int _tab = 0;
  int _photo = 0;
  CompoundPhase? _phaseFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final res = await sl<ApiClient>().get(
        ApiEndpoints.compoundById(widget.compoundId),
        headers: ApiClient.apiV2,
      );
      final raw = res.data['data'];
      if (raw is! Map<String, dynamic>) throw const FormatException();
      if (mounted) setState(() => _data = CompoundPageData.fromJson(raw));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  bool get _ar => isArabic(context);

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: d == null || d.images.isEmpty
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: _failed
            ? _Failure(onRetry: _load)
            : d == null
            ? _Loading(name: widget.name)
            : Column(
                children: [
                  Expanded(child: _content(d)),
                  CallBar(
                    label: 'compound.call_to_book'.tr(),
                    caption: d.minPrice == null
                        ? null
                        : 'compound.starting_from'.tr(),
                    captionValue: d.minPrice == null
                        ? null
                        : '${compactPrice(d.minPrice!)} ${'explore.egp'.tr()}',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _content(CompoundPageData d) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _gallery(d),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.name.pick(_ar), style: JV2.display(context, 31)),
              if (d.area.pick(_ar).isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: JV2.inkMute,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      d.area.pick(_ar),
                      style: const TextStyle(fontSize: 13.5, color: JV2.inkSub),
                    ),
                  ],
                ),
              ],
              if (d.developer != null) ...[
                const SizedBox(height: 14),
                _developerRow(d.developer!),
              ],
              if (d.latestUpdate != null) ...[
                const SizedBox(height: 14),
                _updateBanner(d.latestUpdate!),
              ],
              const SizedBox(height: 16),
              StatStrip([
                (
                  d.minPrice == null ? '—' : compactPrice(d.minPrice!),
                  'compound.stat_from'.tr(),
                ),
                ('${d.unitsCount}', 'compound.stat_listings'.tr()),
                if (d.deliveredSince != null)
                  ('${d.deliveredSince}', 'compound.stat_delivered'.tr()),
              ]),
              const SizedBox(height: 16),
              AskContextCard(scope: AskScope(AskScopeType.compound, d.id, d.name.pick(_ar))),
              const SizedBox(height: 20),
              PageTabs(
                labels: [
                  'compound.tab_units'.tr(),
                  'compound.tab_phases'.tr(),
                  'compound.tab_about'.tr(),
                ],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 18),
              switch (_tab) {
                0 => _units(d),
                1 => _phases(d),
                _ => _about(d),
              },
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // ── gallery ────────────────────────────────────────────

  Widget _gallery(CompoundPageData d) {
    final top = MediaQuery.of(context).padding.top;
    final tagText = CompoundStatusChip.label(
      d.status == 'new_launch' ? 'new_launch' : null,
    );
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (d.images.isEmpty)
            const Photo(radius: 0)
          else
            PageView.builder(
              itemCount: d.images.length,
              onPageChanged: (i) => setState(() => _photo = i),
              itemBuilder: (_, i) => Photo(url: d.images[i], radius: 0),
            ),
          // keep the top controls legible on any photo
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x66000000), Color(0x00000000)],
                ),
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
                _FollowHeart(compoundId: d.id, initial: d.isFollowing),
              ],
            ),
          ),
          if (tagText != null)
            PositionedDirectional(
              start: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: JV2.navy,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tagText.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (d.status != null &&
              CompoundStatusChip.label(d.status) != null)
            PositionedDirectional(
              start: 16,
              bottom: 16,
              child: CompoundStatusChip(d.status),
            ),
          if (d.images.length > 1)
            PositionedDirectional(
              end: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'compound.photo_count'.tr(
                    args: ['${_photo + 1}', '${d.images.length}'],
                  ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _developerRow(CompoundDeveloperBrief dev) {
    final name = dev.name.pick(_ar);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeveloperPage(developerId: dev.id, name: name),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: JV2.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: JV2.line),
            ),
            child: (dev.logo ?? '').isNotEmpty
                ? Photo(url: dev.logo, width: 34, height: 34, radius: 10)
                : Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: JV2.display(context, 16),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'compound.developed_by'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: JV2.inkMute,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: JV2.ink,
                        ),
                      ),
                    ),
                    if (dev.isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: JV2.success,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(chevronIcon(context), size: 18, color: JV2.inkMute),
        ],
      ),
    );
  }

  Widget _updateBanner(CompoundUpdate u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: JV2.goldFilm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JV2.goldEdge),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, size: 18, color: JV2.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              u.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JV2.gold,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── tabs ───────────────────────────────────────────────

  Widget _units(CompoundPageData d) {
    final phase = _phaseFilter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (phase != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () => setState(() => _phaseFilter = null),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                decoration: BoxDecoration(
                  color: JV2.fillHi,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'compound.phase_filter'.tr(args: [phase.name.pick(_ar)]),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: JV2.navy,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.close_rounded, size: 15, color: JV2.navy),
                  ],
                ),
              ),
            ),
          ),
        LiveListings(
          key: ValueKey('units-${d.id}-${phase?.id}'),
          query: {'compound_id': d.id, if (phase != null) 'phase_id': phase.id},
          emptyText: 'compound.units_empty'.tr(),
        ),
      ],
    );
  }

  Widget _phases(CompoundPageData d) {
    if (d.phases.isEmpty) {
      return EmptyBlock(
        icon: Icons.layers_outlined,
        title: 'compound.phases_empty_title'.tr(),
        sub: 'compound.phases_empty_sub'.tr(),
      );
    }
    return Column(
      children: [
        for (final p in d.phases)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PhaseCard(
              phase: p,
              onTap: p.available > 0
                  ? () => setState(() {
                      _phaseFilter = p;
                      _tab = 0;
                    })
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _about(CompoundPageData d) {
    final desc = d.desc.pick(_ar);
    final rows = _factRows(d);
    final facilities = d.facilities(_ar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desc.isNotEmpty) ...[
          Text(desc, style: JV2.sub),
          const SizedBox(height: 22),
        ],
        if (rows.isNotEmpty) ...[
          Text(
            'compound.facts_title'.tr().toUpperCase(),
            style: JV2.eyebrow.copyWith(fontSize: 10, letterSpacing: 1.8),
          ),
          const SizedBox(height: 4),
          for (final r in rows) InfoRow(r.$1, r.$2),
          const SizedBox(height: 24),
        ],
        Text(
          'compound.facilities'.tr().toUpperCase(),
          style: JV2.eyebrow.copyWith(fontSize: 10, letterSpacing: 1.8),
        ),
        const SizedBox(height: 12),
        if (facilities.isEmpty)
          Text(
            'compound.facilities_empty'.tr(),
            style: JV2.sub.copyWith(fontSize: 13.5),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final f in facilities) _FacilityTile(f)],
          ),
      ],
    );
  }

  /// The computed rows first (so they are always right), then whatever was typed in the dashboard.
  List<(String, String)> _factRows(CompoundPageData d) {
    final nf = NumberFormat.decimalPattern(context.locale.toString());
    final rows = <(String, String)>[];

    if (d.area.pick(_ar).isNotEmpty)
      rows.add(('compound.row_location'.tr(), d.area.pick(_ar)));
    if (d.unitTypes.isNotEmpty) {
      rows.add((
        'compound.row_unit_types'.tr(),
        d.unitTypes.map((t) => 'type.$t'.tr()).join(' · '),
      ));
    }
    if (d.sizeMin != null && d.sizeMax != null) {
      final a = nf.format(d.sizeMin!.round());
      final b = nf.format(d.sizeMax!.round());
      rows.add((
        'compound.row_size'.tr(),
        a == b
            ? 'compound.size_one'.tr(args: [a])
            : 'compound.size_range'.tr(args: [a, b]),
      ));
    }
    final delivery = _deliveryText(d.deliveryDate);
    if (delivery != null) rows.add(('compound.row_delivery'.tr(), delivery));
    if (d.deliveredSince != null)
      rows.add(('compound.row_delivered_since'.tr(), '${d.deliveredSince}'));
    if (d.finishing != null)
      rows.add((
        'compound.row_finishing'.tr(),
        'compound.fin_${d.finishing}'.tr(),
      ));
    final payment = _paymentText(d);
    if (payment != null) rows.add(('compound.row_payment'.tr(), payment));

    for (final f in d.facts) {
      final label = f.label.pick(_ar);
      final value = f.value.pick(_ar);
      if (label.isNotEmpty && value.isNotEmpty) rows.add((label, value));
    }
    return rows;
  }

  String? _deliveryText(String? raw) {
    final date = raw == null ? null : DateTime.tryParse(raw);
    if (date == null) return null;
    return date.isAfter(DateTime.now())
        ? '${date.year}'
        : 'compound.ready'.tr();
  }

  String? _paymentText(CompoundPageData d) {
    final parts = <String>[
      ...d.paymentOptions.map((o) => 'compound.pay_$o'.tr()),
    ];
    final extra = <String>[
      if (d.downPaymentPercent != null)
        'compound.payment_down'.tr(
          args: [
            d.downPaymentPercent! % 1 == 0
                ? '${d.downPaymentPercent!.toInt()}'
                : '${d.downPaymentPercent}',
          ],
        ),
      if (d.installmentYears != null)
        'compound.payment_years'.tr(args: ['${d.installmentYears}']),
    ];
    if (parts.isEmpty && extra.isEmpty) return null;
    return [
      parts.join(' · '),
      extra.join(' · '),
    ].where((s) => s.isNotEmpty).join('\n');
  }
}

// ── bits ─────────────────────────────────────────────────

/// Heart = follow. Optimistic; reverts with a message if the call fails.
class _FollowHeart extends StatefulWidget {
  final int compoundId;
  final bool initial;
  const _FollowHeart({required this.compoundId, required this.initial});

  @override
  State<_FollowHeart> createState() => _FollowHeartState();
}

class _FollowHeartState extends State<_FollowHeart> {
  late bool _on = widget.initial;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    final was = _on;
    setState(() {
      _on = !was;
      _busy = true;
    });
    final service = sl<FollowService>();
    try {
      was
          ? await service.unfollow(FollowType.project, widget.compoundId)
          : await service.follow(FollowType.project, widget.compoundId);
    } catch (_) {
      if (mounted) {
        setState(() => _on = was);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('compound.follow_failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: JV2.shadowMd,
        ),
        child: Icon(
          _on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 21,
          color: _on ? JV2.danger : JV2.ink,
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final CompoundPhase phase;
  final VoidCallback? onTap;
  const _PhaseCard({required this.phase, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final (bg, fg) = switch (phase.status) {
      'selling_now' => (const Color(0x1A137A55), JV2.success),
      'resale_only' => (JV2.goldFilm, JV2.gold),
      'sold_out' => (const Color(0x14C23B3B), JV2.danger),
      _ => (JV2.fillHi, JV2.inkSub),
    };
    final status = switch (phase.status) {
      'selling_now' => 'compound.phase_selling_now'.tr(),
      'resale_only' => 'compound.phase_resale_only'.tr(),
      'sold_out' => 'compound.phase_sold_out'.tr(),
      _ => 'compound.phase_coming_soon'.tr(),
    };
    final delivery = phase.delivery.pick(ar);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JV2.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase.name.pick(ar), style: JV2.display(context, 21)),
                  if (delivery.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      delivery,
                      style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
                    ),
                  ],
                  if (phase.available > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                        'compound.n_available'.plural(phase.available),
                        if (phase.minPrice != null)
                          '${'explore.from_price'.tr(args: [compactPrice(phase.minPrice!)])} ${'explore.egp'.tr()}',
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: JV2.ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 10),
                  Icon(chevronIcon(context), size: 18, color: JV2.inkMute),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityTile extends StatelessWidget {
  final String text;
  const _FacilityTile(this.text);

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 40 - 10) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JV2.line),
      ),
      child: Row(
        children: [
          Icon(facilityIcon(text), size: 20, color: JV2.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: JV2.ink,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final String? name;
  const _Loading({this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        if (name != null && name!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(name!, style: JV2.display(context, 30)),
            ),
          ),
        const Expanded(
          child: Center(child: CircularProgressIndicator(color: JV2.navy)),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  final VoidCallback onRetry;
  const _Failure({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  onPressed: onRetry,
                  child: Text('explore.try_again'.tr()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
