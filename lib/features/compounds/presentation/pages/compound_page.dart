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
import '../../../follow/presentation/follow_alerts.dart';
import '../../../units/presentation/unit_widgets.dart';
import '../../../../core/widgets/shared_photo.dart';
import '../../data/compound_page_data.dart';
import '../widgets/compound_media.dart';
import '../widgets/compound_units.dart';
import 'compound_media_pages.dart';
import '../widgets/facility_icon.dart';
import '../widgets/page_widgets.dart';

/// A compound's page: gallery, key figures, then Units / Phases / About.
/// Following turns on every notification for it (the bell mutes them without unfollowing). "Call to book a viewing"
/// dials the number saved in the dashboard settings.
class CompoundPage extends StatefulWidget {
  final int compoundId;
  final String? name; // shown while loading
  final Object? heroTag; // the card's photo flies into the gallery when this is set (see SharedPhoto)

  const CompoundPage({super.key, required this.compoundId, this.name, this.heroTag});

  @override
  State<CompoundPage> createState() => _CompoundPageState();
}

class _CompoundPageState extends State<CompoundPage> {
  CompoundPageData? _data;
  bool _failed = false;
  int _tab = 0;
  int _photo = 0;
  FollowController? _follow; // created once the compound has loaded

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
      if (mounted) {
        final data = CompoundPageData.fromJson(raw);
        setState(() {
          _data = data;
          _follow = FollowController(
            service: sl<FollowService>(),
            type: FollowType.project,
            id: data.id,
            name: data.name.pick(_ar),
            following: data.isFollowing,
            alertsOn: data.alertsOn,
          );
        });
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(d.name.pick(_ar), style: JV2.display(context, 31)),
                  ),
                  if (d.status == 'selling' && d.unitsCount > 0) ...[
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        key: const Key('selling-tag'),
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: const Color(0x14137A55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: JV2.success,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'unit.selling'.tr(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: JV2.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (d.area.pick(_ar).isNotEmpty || d.developer != null) ...[
                const SizedBox(height: 6),
                _byLine(d),
              ],
              if (d.latestUpdate != null) ...[
                const SizedBox(height: 14),
                _updateBanner(d.latestUpdate!),
              ],
              const SizedBox(height: 16),
              if (d.minPrice != null && d.sizeMin != null && d.sizeMax != null) ...[
                CompoundPriceLine(minPrice: d.minPrice!, sizeMin: d.sizeMin, sizeMax: d.sizeMax),
                if (d.unitTypes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  TypeChips(d.unitTypes),
                ],
              ] else
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
              MediaTiles(
                photos: d.images.length,
                hasPlan: d.masterPlan != null,
                onPlan: () => openMasterPlan(context, name: d.name.pick(_ar), url: d.masterPlan!),
                onGallery: () => openGallery(context, name: d.name.pick(_ar), images: d.images),
              ),
              if (d.hasPin) ...[
                const SizedBox(height: 12),
                // the location card; tapping it does nothing yet (no map screen)
                MapCard(area: d.area.pick(_ar).isNotEmpty ? d.area.pick(_ar) : d.name.pick(_ar)),
              ],
              const SizedBox(height: 16),
              if (_follow != null) ...[
                AlertsStrip(c: _follow!),
                const SizedBox(height: 16),
              ],
              AskContextCard(
                scope: AskScope(AskScopeType.compound, d.id, d.name.pick(_ar)),
              ),
              const SizedBox(height: 20),
              PageTabs(
                labels: [
                  'compound.tab_primary'.tr(),
                  'compound.tab_resale'.tr(),
                  'compound.tab_about'.tr(),
                ],
                index: _tab,
                counts: [d.primaryCount, d.resaleCount, null],
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 18),
              switch (_tab) {
                0 => _listings(d, 'primary'),
                1 => _listings(d, 'resale'),
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
      height: 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (d.images.isEmpty)
            const Photo(radius: 0)
          else
            PageView.builder(
              itemCount: d.images.length,
              onPageChanged: (i) => setState(() => _photo = i),
              itemBuilder: (_, i) => GestureDetector(
                key: Key('hero-photo-$i'),
                onTap: () => openPhotos(context, name: d.name.pick(_ar), images: d.images, index: i),
                child: i == 0 && widget.heroTag != null
                    ? SharedPhoto(tag: widget.heroTag!, child: Photo(url: d.images[i], radius: 0))
                    : Photo(url: d.images[i], radius: 0),
              ),
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
                if (_follow != null) ...[
                  HeroFollow(c: _follow!),
                  const SizedBox(width: 8),
                  HeroBell(c: _follow!),
                ],
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
              d.status != 'selling' &&
              CompoundStatusChip.label(d.status) != null)
            PositionedDirectional(
              start: 16,
              bottom: 16,
              child: CompoundStatusChip(d.status),
            ),
          if (d.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < d.images.length.clamp(0, 7); i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: i == _photo.clamp(0, 6) ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _photo.clamp(0, 6)
                              ? Colors.white
                              : const Color(0x8CFFFFFF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
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

  /// "New Cairo · by Redwood Developments" — the developer's name opens its page.
  Widget _byLine(CompoundPageData d) {
    final area = d.area.pick(_ar);
    final dev = d.developer;
    final name = dev?.name.pick(_ar) ?? '';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (area.isNotEmpty)
          Text(
            dev == null ? area : '$area · ${'compound.by'.tr()} ',
            style: const TextStyle(fontSize: 13, color: JV2.inkSub),
          ),
        if (dev != null)
          GestureDetector(
            key: const Key('developer-link'),
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeveloperPage(developerId: dev.id, name: name),
              ),
            ),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: JV2.navy,
              ),
            ),
          ),
      ],
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

  /// Primary = sold by the developer; Resale = sold by owners and brokers.
  Widget _listings(CompoundPageData d, String type) {
    // a compound with no units of this kind stays visible: following it says when units appear
    if (type == 'primary' && d.primaryCount == 0) {
      return NoUnitsBlock(name: d.name.pick(_ar), follow: _follow);
    }
    if (type == 'resale' && d.resaleCount == 0) {
      return NoUnitsBlock(name: d.name.pick(_ar), resale: true, follow: _follow);
    }
    if (type == 'primary') {
      return CompoundUnits(key: ValueKey('units-${d.id}'), compoundId: d.id);
    }
    return LiveListings(
      key: ValueKey('$type-${d.id}'),
      query: {'compound_id': d.id, 'listing_type': type},
      emptyText: 'compound.${type}_empty'.tr(),
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
          ReadMoreText(desc),
          const SizedBox(height: 22),
        ],
        if (d.faqs.isNotEmpty) ...[
          FaqList(faqs: d.faqs, arabic: _ar),
          const SizedBox(height: 24),
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
        if (d.developer != null) ...[
          const SizedBox(height: 24),
          UnitSecHead('unit.developer'.tr()),
          const SizedBox(height: 12),
          DevMiniCard(
            dev: d.developer!,
            arabic: _ar,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeveloperPage(
                  developerId: d.developer!.id,
                  name: d.developer!.name.pick(_ar),
                ),
              ),
            ),
          ),
        ],
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
