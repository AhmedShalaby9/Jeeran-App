import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../compounds/presentation/pages/compound_page.dart';
import '../../explore/presentation/widgets/explore_widgets.dart'
    show Photo, chevronIcon, isArabic;
import '../../news/presentation/pages/news_details_page.dart'
    show NewsVideoPage;
import '../../properties/data/models/property_model.dart';
import '../../units/data/unit_format.dart';
import '../../units/presentation/unit_card.dart';
import '../../units/presentation/unit_widgets.dart';
import '../data/search_api.dart';

/// One launch or offer: its photo or video, what it is, how long it runs, what it starts from, the compound
/// it belongs to and the units it covers. Opened from the Launches & offers list and the Search rails.
class PromotionPage extends StatefulWidget {
  final PromotionItem item;
  final SearchApi api;
  const PromotionPage({super.key, required this.item, required this.api});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  PromotionDetail? _detail;
  bool _failed = false;

  PromotionItem get _p => widget.item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final d = await widget.api.promotion(_p.id);
      if (mounted) setState(() => _detail = d);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _openCompound() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CompoundPage(
        compoundId: _p.compoundId,
        name: _p.compoundName(isArabic(context)),
      ),
    ),
  );

  /// Promotion units carry no compound of their own: give each the compound's name so the card reads like the rest.
  Widget _unit(Map<String, dynamic> raw) {
    final fixed = {
      ...raw,
      'price': raw['price']?.toString(),
      'size': raw['size']?.toString(),
      'listing_type': 'primary',
      'project':
          raw['project'] ??
          {
            'id': _p.compoundId,
            'name_ar': _p.compoundNameAr,
            'name_en': _p.compoundNameEn,
          },
      if (_p.type == 'launch') 'is_launch': true else 'has_offer': true,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: UnitCard(
        property: PropertyModel.fromJson(fixed),
        key: ValueKey('promo-unit-${raw['id']}'),
        compact: true,
      ),
    );
  }

  String? _endsText(DateTime? end) {
    if (end == null) return 'promo.ongoing'.tr();
    final days = end.difference(DateTime.now()).inDays;
    final date = DateFormat.yMMMd(context.locale.toString()).format(end);
    if (days < 0) return null;
    if (days <= 14) return '${'promo.ends_in_days'.plural(days)} · $date';
    return 'promo.ends_on'.tr(args: [date]);
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final launch = _p.type == 'launch';
    final detail = _detail;
    final end = detail?.endsAt ?? _p.endsAt;
    final endsText = _endsText(end);
    final units = detail?.units ?? const <Map<String, dynamic>>[];
    final video = detail?.videoUrl;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      key: const Key('promotion-page'),
      backgroundColor: JV2.bgDeep,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Photo(url: _p.image, radius: 0),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x420B2A4A),
                            Color(0x000B2A4A),
                            Color(0x8F0B2A4A),
                          ],
                          stops: [0, 0.4, 1],
                        ),
                      ),
                    ),
                    if (video != null || _p.hasVideo)
                      Center(
                        child: GestureDetector(
                          key: const Key('promo-play'),
                          onTap: video == null
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NewsVideoPage(url: video),
                                  ),
                                ),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0x8F0B2A4A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white54),
                            ),
                            child: video == null
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      start: 20,
                      bottom: 16,
                      child: launch
                          ? const UnitTag.launch()
                          : const UnitTag.offer(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _p.title(ar),
                      key: const Key('promo-title'),
                      style: JV2.display(context, 26).copyWith(height: 1.15),
                    ),
                    if (_p.sub(ar).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _p.sub(ar),
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: JV2.inkSub,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_p.minPrice != null)
                          Expanded(
                            child: _Stat(
                              label: 'unit.from'.tr(),
                              value:
                                  '${'unit.egp'.tr()} ${fmtShort(_p.minPrice!)}',
                              key: const Key('promo-from'),
                            ),
                          ),
                        if (_p.minPrice != null && endsText != null)
                          const SizedBox(width: 10),
                        if (endsText != null)
                          Expanded(
                            child: _Stat(
                              label: 'promo.runs'.tr(),
                              value: endsText,
                              key: const Key('promo-ends'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      key: const Key('promo-compound'),
                      onTap: _openCompound,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: JV2.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: JV2.line),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: JV2.navy,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _p.compoundName(ar),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: JV2.ink,
                                    ),
                                  ),
                                  if (_p.developerName(ar).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        _p.developerName(ar),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: JV2.inkSub,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'promo.view_compound'.tr(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: JV2.navy,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              chevronIcon(context),
                              size: 16,
                              color: JV2.inkMute,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_failed)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'explore.load_failed'.tr(),
                              style: const TextStyle(color: JV2.inkSub),
                            ),
                            const SizedBox(height: 10),
                            JV2PrimaryButton(
                              width: 140,
                              height: 44,
                              onPressed: _load,
                              child: Text('prop.retry'.tr()),
                            ),
                          ],
                        ),
                      )
                    else if (detail == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: JV2.goldHi,
                          ),
                        ),
                      )
                    else if (units.isNotEmpty) ...[
                      Text(
                        (launch ? 'promo.units_launch' : 'promo.units_offer')
                            .plural(units.length),
                        key: const Key('promo-units-title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final u in units) _unit(u),
                    ] else
                      Container(
                        key: const Key('promo-whole-compound'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: JV2.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JV2.line),
                        ),
                        child: Text(
                          'promo.whole_compound'.tr(
                            namedArgs: {'name': _p.compoundName(ar)},
                          ),
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: JV2.inkSub,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          PositionedDirectional(
            start: 16,
            top: top + 8,
            child: GestureDetector(
              key: const Key('promo-back'),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xE6FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isArabic(context)
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 24,
                  color: JV2.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: JV2.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: JV2.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: JV2.inkMute,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: JV2.ink,
          ),
        ),
      ],
    ),
  );
}
