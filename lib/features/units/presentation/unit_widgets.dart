import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../data/payment_plan.dart';
import '../data/unit_format.dart';

// The pieces of the Nawy data update (design D1–D6) that more than one screen uses:
// Launch / Offer marks, the payment-plan selector + summary + timeline, floor plans, section heads.

const double kUnitPad = 20;
const Color _offerFill = Color(0xFFFFF6E6);

/// Looked up by the unit's `property_type`; the four newest types have their own glyph.
IconData typeIcon(String? key) => switch (key) {
      'villa' => Icons.house_rounded,
      'apartment' => Icons.apartment_rounded,
      'chalet' => Icons.cabin_rounded,
      'marina_apartment' => Icons.water_rounded,
      'clinic' => Icons.local_hospital_rounded,
      'office' => Icons.business_center_rounded,
      'shop' => Icons.storefront_rounded,
      'twinhouse' => Icons.holiday_village_rounded,
      'townhouse' => Icons.home_work_rounded,
      'duplex' => Icons.layers_rounded,
      'studio' => Icons.single_bed_rounded,
      'land' => Icons.landscape_rounded,
      'penthouse' => Icons.roofing_rounded,
      'loft' => Icons.deck_rounded,
      'cabin' => Icons.cottage_rounded,
      'family_house' => Icons.family_restroom_rounded,
      _ => Icons.apartment_rounded,
    };

/// "Launch" (navy) or "Offer" / "Offer − 35%" (tan). The percent shows only when it is above 0.
class UnitTag extends StatelessWidget {
  final bool launch;
  final double? pct;
  const UnitTag.launch({super.key})
      : launch = true,
        pct = null;
  const UnitTag.offer({super.key, this.pct}) : launch = false;

  @override
  Widget build(BuildContext context) {
    final p = pct == null || pct! <= 0 ? null : (pct! == pct!.roundToDouble() ? pct!.round().toString() : pct!.toString());
    final text = launch
        ? 'unit.launch'.tr()
        : (p == null ? 'unit.offer'.tr() : 'unit.offer_pct'.tr(namedArgs: {'pct': p}));
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: launch ? JV2.navy : _offerFill,
        borderRadius: BorderRadius.circular(7),
        border: launch ? null : Border.all(color: JV2.goldEdge),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: launch ? Colors.white : JV2.warnText,
        ),
      ),
    );
  }
}

/// Section title: serif heading, a quiet meta line, an optional action on the far side.
class UnitSecHead extends StatelessWidget {
  final String title;
  final String? meta;
  final Widget? action;
  const UnitSecHead(this.title, {super.key, this.meta, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: JV2.display(context, 22)),
        if (meta != null) ...[
          const SizedBox(width: 10),
          Flexible(child: Text(meta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: JV2.inkSub))),
        ],
        if (action != null) ...[const Spacer(), action!],
      ],
    );
  }
}

String _per(String? frequency) => 'unit.per_${_freqKey(frequency)}'.tr();
String _freqKey(String? f) => switch (f) {
      'monthly' => 'monthly',
      'semi-annually' => 'semiannual',
      'annually' => 'annual',
      _ => 'quarterly',
    };

String _pct(double? v) => v == null ? '0' : (v == v.roundToDouble() ? v.round().toString() : v.toString());

/// "From 347K / quarter" for the plan the unit opens on; null when it has no instalments.
String? fromPerPeriod(PaymentPlan? p) {
  if (p == null || p.payInFull) return null;
  return 'unit.from_per'.tr(namedArgs: {'amount': fmtShort(p.installment!), 'per': _per(p.frequency)});
}

String planLabel(PaymentPlan p) =>
    p.payInFull ? 'unit.plan_cash'.tr() : 'unit.plan_label'.tr(namedArgs: {'years': '${p.years}', 'dp': _pct(p.downPercent)});

// ── payment plans: chips → one summary card ───────────────

class PlanChips extends StatelessWidget {
  final List<PaymentPlan> plans;
  final int selected;
  final ValueChanged<int> onSelect;
  const PlanChips({super.key, required this.plans, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kUnitPad),
        itemCount: plans.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = plans[i];
          final on = i == selected;
          return GestureDetector(
            key: Key('plan-chip-$i'),
            onTap: () => onSelect(i),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: on ? JV2.navy : JV2.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: on ? JV2.navy : JV2.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(planLabel(p), style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w700 : FontWeight.w600, color: on ? Colors.white : JV2.ink)),
                  if (p.hasOffer) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: on ? const Color(0x2EFFFFFF) : _offerFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.discount != null ? '−${_pct(p.discount)}%' : 'unit.offer'.tr(),
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: on ? const Color(0xFFF3D9A8) : JV2.warnText),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One line: down payment, lump sums and the delivery date laid on a single bar.
class PlanTimeline extends StatelessWidget {
  final PaymentPlan plan;
  final int? deliveryYear;
  final int startYear;
  const PlanTimeline({super.key, required this.plan, this.deliveryYear, required this.startYear});

  @override
  Widget build(BuildContext context) {
    if (plan.payInFull || plan.years <= 0) return const SizedBox.shrink();
    final toDelivery = deliveryYear == null ? null : (deliveryYear! - startYear).clamp(0, 30).toDouble();
    final span = [plan.years.toDouble(), toDelivery ?? 0].reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        double x(double years) => (years / span).clamp(0, 1) * w;
        final labels = <(double, String, bool)>[
          for (final b in plan.bulk) (x(b.atYears), '${'unit.tl_lump'.tr()}\n${'unit.tl_year'.tr(namedArgs: {'y': _pct(b.atYears)})}', false),
          if (toDelivery != null) (x(toDelivery), '${'unit.tl_delivery'.tr()}\n$deliveryYear', true),
        ];
        return Column(
          children: [
            SizedBox(
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    top: 11,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(color: JV2.track, borderRadius: BorderRadius.circular(4)),
                      clipBehavior: Clip.antiAlias,
                      child: Row(children: [
                        Container(width: 10, color: JV2.goldHi),
                        Container(width: x(plan.years.toDouble()) - 10 < 0 ? 0 : x(plan.years.toDouble()) - 10, color: const Color(0x731A4A80)),
                      ]),
                    ),
                  ),
                  for (final b in plan.bulk)
                    PositionedDirectional(
                      start: x(b.atYears) - 2,
                      top: 7,
                      child: Container(width: 4, height: 16, decoration: BoxDecoration(color: JV2.navy, borderRadius: BorderRadius.circular(2))),
                    ),
                  if (toDelivery != null)
                    PositionedDirectional(
                      start: x(toDelivery) - 7,
                      top: 3,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: JV2.success, width: 2.5)),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(start: 0, child: _tl('${'unit.tl_down'.tr()}\n$startYear', JV2.inkSub)),
                  for (final (pos, text, green) in labels)
                    PositionedDirectional(start: (pos - 28).clamp(0, w - 56), child: SizedBox(width: 56, child: _tl(text, green ? JV2.success : JV2.inkSub, center: true, bold: green))),
                  PositionedDirectional(end: 0, child: _tl('${'unit.tl_last'.tr()}\n${startYear + plan.years}', JV2.inkSub, end: true)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _tl(String t, Color color, {bool center = false, bool end = false, bool bold = false}) => Text(
        t,
        textAlign: center ? TextAlign.center : (end ? TextAlign.end : TextAlign.start),
        style: TextStyle(fontSize: 10.5, height: 1.3, color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      );
}

class PlanSummary extends StatelessWidget {
  final PaymentPlan plan;
  final double? headline;
  final double? maintenance;
  final int? deliveryYear;
  final int? startYear;
  final bool compact;
  const PlanSummary({super.key, required this.plan, this.headline, this.maintenance, this.deliveryYear, this.startYear, this.compact = false});

  Widget _row(String k, double? v, {String? sub, bool strong = false}) {
    if (v == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: JV2.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k, style: const TextStyle(fontSize: 12.5, color: JV2.inkSub)),
                if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub, style: const TextStyle(fontSize: 11, color: JV2.inkMute))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('EGP ${fmtFull(v)}', style: TextStyle(fontSize: strong ? 15 : 13.5, fontWeight: strong ? FontWeight.w700 : FontWeight.w600, color: JV2.ink, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final full = p.payInFull;
    final total = p.unitPrice;
    final fee = maintenance ?? p.maintenance;
    final lower = headline != null && total != null && total < headline!;
    return Container(
      key: const Key('plan-summary'),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 6),
      decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: JV2.line), boxShadow: JV2.shadowMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (full ? 'unit.pay_in_full'.tr() : 'unit.freq_n'.tr(namedArgs: {'freq': 'unit.f_${_freqKey(p.frequency)}'.tr(), 'n': '${p.instalments}'})).toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: JV2.inkSub),
                    ),
                    const SizedBox(height: 4),
                    if (full)
                      Text('EGP ${fmtFull(total ?? 0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: JV2.ink, letterSpacing: -0.3))
                    else
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'EGP ${fmtFull(p.installment!)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: JV2.ink, letterSpacing: -0.3)),
                        TextSpan(text: ' / ${_per(p.frequency)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: JV2.inkSub)),
                      ])),
                  ],
                ),
              ),
              if (p.hasOffer) UnitTag.offer(pct: p.discount),
            ],
          ),
          const SizedBox(height: 12),
          if (!compact) PlanTimeline(plan: p, deliveryYear: deliveryYear, startYear: startYear ?? DateTime.now().year),
          if (!full) _row('unit.down_payment'.tr(namedArgs: {'pct': _pct(p.downPercent)}), p.downPayment, sub: 'unit.at_contract'.tr()),
          for (final b in p.bulk) _row('unit.lump_year'.tr(namedArgs: {'y': _pct(b.atYears)}), b.value),
          if (!full) _row('unit.total_instalments'.tr(), p.totalInstalments),
          _row('unit.price_on_plan'.tr(), total, strong: true, sub: lower ? 'unit.plan_priced_note'.tr() : null),
          if (!compact && fee != null && !p.maintenanceIncluded) _row('unit.maintenance_once'.tr(), fee, sub: 'unit.not_in_price'.tr()),
          if (p.isBackLoaded && !compact)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(color: JV2.fillFaint, borderRadius: BorderRadius.circular(10)),
              child: Text('unit.back_loaded'.tr(), style: const TextStyle(fontSize: 11.5, height: 1.45, color: JV2.ink)),
            ),
          if (!p.isBackLoaded || compact) const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Section: heading, the plan chips, the one summary card that follows the chosen chip.
class PlansBlock extends StatefulWidget {
  final List<PaymentPlan> plans;
  final double? headline;
  final int? deliveryYear;
  final double? downPercent;
  final int? years;
  const PlansBlock({super.key, required this.plans, this.headline, this.deliveryYear, this.downPercent, this.years});

  @override
  State<PlansBlock> createState() => _PlansBlockState();
}

class _PlansBlockState extends State<PlansBlock> {
  late int _sel = () {
    final d = defaultPlan(widget.plans, downPercent: widget.downPercent, years: widget.years);
    final i = d == null ? 0 : widget.plans.indexOf(d);
    return i < 0 ? 0 : i;
  }();

  @override
  Widget build(BuildContext context) {
    final plans = widget.plans;
    if (plans.isEmpty) return const SizedBox.shrink();
    final plan = plans[_sel.clamp(0, plans.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kUnitPad),
          child: UnitSecHead('unit.payment_plans'.tr(), meta: 'unit.plans_meta'.tr(namedArgs: {'n': '${plans.length}'})),
        ),
        const SizedBox(height: 12),
        if (plans.length > 1) PlanChips(plans: plans, selected: _sel, onSelect: (i) => setState(() => _sel = i)),
        if (plans.length > 1) const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kUnitPad),
          child: PlanSummary(plan: plan, headline: widget.headline, deliveryYear: widget.deliveryYear),
        ),
      ],
    );
  }
}

// ── details list, floor plans, who's selling ──────────────

class UnitFacts extends StatelessWidget {
  final List<(String, String?)> rows;
  const UnitFacts({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final shown = rows.where((r) => r.$2 != null && r.$2!.trim().isNotEmpty).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: JV2.line)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: JV2.line))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(width: 128, child: Text(shown[i].$1, style: const TextStyle(fontSize: 12.5, color: JV2.inkSub))),
                  Expanded(child: Text(shown[i].$2!, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: JV2.ink))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class FloorPlansBlock extends StatelessWidget {
  final List<String> urls;
  const FloorPlansBlock({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnitSecHead('unit.floor_plans'.tr(), meta: 'unit.n_plans'.tr(namedArgs: {'n': '${urls.length}'})),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: urls.length == 1 ? 1 : 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: urls.length == 1 ? 1.9 : 1.05),
          itemCount: urls.length,
          itemBuilder: (context, i) => GestureDetector(
            key: Key('floor-plan-$i'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => FloorPlanViewer(urls: urls, initial: i))),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF6F8FB), borderRadius: BorderRadius.circular(14), border: Border.all(color: JV2.line)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: urls[i], fit: BoxFit.contain, errorWidget: (_, _, _) => const SizedBox.shrink(), placeholder: (_, _) => const SizedBox.shrink()),
                  PositionedDirectional(
                    end: 8,
                    bottom: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: JV2.line)),
                      child: const Icon(Icons.open_in_full_rounded, size: 13, color: JV2.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen floor plan: swipe between plans, pinch to zoom.
class FloorPlanViewer extends StatefulWidget {
  final List<String> urls;
  final int initial;
  const FloorPlanViewer({super.key, required this.urls, this.initial = 0});

  @override
  State<FloorPlanViewer> createState() => _FloorPlanViewerState();
}

class _FloorPlanViewerState extends State<FloorPlanViewer> {
  late final _ctl = PageController(initialPage: widget.initial);
  late int _page = widget.initial;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1726),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    key: const Key('floor-plan-close'),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.close_rounded, size: 18, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('unit.floor_plans'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                  Text('${_page + 1} / ${widget.urls.length}', style: const TextStyle(fontSize: 12.5, color: Color(0xA6FFFFFF))),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctl,
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFF6F8FB), borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(minScale: 1, maxScale: 5, child: CachedNetworkImage(imageUrl: widget.urls[i], fit: BoxFit.contain, errorWidget: (_, _, _) => const SizedBox.shrink())),
                ),
              ),
            ),
            if (widget.urls.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 18, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.urls.length; i++)
                      Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: i == _page ? 18 : 6, height: 6, decoration: BoxDecoration(color: i == _page ? Colors.white : const Color(0x59FFFFFF), borderRadius: BorderRadius.circular(3))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Sold by the developer": developer inventory has no individual seller, so no call or WhatsApp.
class DevInventoryCard extends StatelessWidget {
  final String developerName;
  final String? asOf;
  final VoidCallback? onTap;
  const DevInventoryCard({super.key, required this.developerName, this.asOf, this.onTap});

  String get _initials {
    final parts = developerName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && RegExp(r'[A-Za-z؀-ۿ]').hasMatch(w[0])).take(2);
    return parts.map((w) => w[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: JV2.line), boxShadow: JV2.shadowMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: JV2.fillFaint, borderRadius: BorderRadius.circular(13), border: Border.all(color: JV2.line)),
                  child: Text(_initials, style: JV2.display(context, 17).copyWith(color: JV2.navy)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('unit.sold_by_dev'.tr().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: JV2.inkSub)),
                      const SizedBox(height: 2),
                      Text(developerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: JV2.ink)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text.rich(TextSpan(children: [
              TextSpan(text: '${'unit.inv_note'.tr()} '),
              if (asOf != null) TextSpan(text: asOf, style: const TextStyle(fontWeight: FontWeight.w700, color: JV2.ink)),
              TextSpan(text: ' ${'unit.inv_may_change'.tr()}'),
            ]), style: const TextStyle(fontSize: 12.5, height: 1.5, color: JV2.inkSub)),
            const SizedBox(height: 13),
            Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: JV2.goldHi, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(child: Text('unit.inv_callback'.tr(), style: const TextStyle(fontSize: 12, color: JV2.inkSub))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
