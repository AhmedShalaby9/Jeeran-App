import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import 'ad_studio_api.dart';

/// Text styles of the studio. Tests replace [displayOverride] (the display font can't download there).
class AdStyles {
  static TextStyle Function(BuildContext, double)? displayOverride;
  static TextStyle display(BuildContext c, double size) => (displayOverride ?? JV2.display)(c, size);
}

const double kAdPad = 20;
const _line = JV2.line;
const _shadowSm = [BoxShadow(color: Color(0x0D0B2A4A), blurRadius: 2, offset: Offset(0, 1))];

/// The design's four-point sparkle.
class AdSpark extends StatelessWidget {
  final double size;
  final Color color;
  const AdSpark({super.key, this.size = 11, this.color = JV2.goldHi});

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _SparkPainter(color)));
}

class _SparkPainter extends CustomPainter {
  final Color color;
  const _SparkPainter(this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 24;
    Offset p(double x, double y) => Offset(x * k, y * k);
    final path = Path()
      ..moveTo(p(12, 2.6).dx, p(12, 2.6).dy)
      ..lineTo(p(13.9, 8.8).dx, p(13.9, 8.8).dy)
      ..lineTo(p(20.1, 10.7).dx, p(20.1, 10.7).dy)
      ..lineTo(p(13.9, 12.6).dx, p(13.9, 12.6).dy)
      ..lineTo(p(12, 18.8).dx, p(12, 18.8).dy)
      ..lineTo(p(10.1, 12.6).dx, p(10.1, 12.6).dy)
      ..lineTo(p(3.9, 10.7).dx, p(3.9, 10.7).dy)
      ..lineTo(p(10.1, 8.8).dx, p(10.1, 8.8).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.color != color;
}

/// "Admin" pill in the header.
class AdminPill extends StatelessWidget {
  const AdminPill({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    alignment: Alignment.center,
    decoration: BoxDecoration(color: JV2.fillFaint, border: Border.all(color: _line), borderRadius: BorderRadius.circular(8)),
    child: Text('adstudio.admin'.tr().toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: JV2.inkSub)),
  );
}

/// Shared frame of every studio screen: back, title, sub-title, optional step bar, the content, and a footer button.
class AdFlowScaffold extends StatelessWidget {
  final String title;
  final String? sub;
  final int? step; // 1..4
  final Widget? right;
  final List<Widget> children;
  final double gap;
  final Widget? bottom;
  final bool canPop;
  final EdgeInsets? padding;
  final Widget? bodyOverride; // replaces the padded column (e.g. the variations carousel needs full-width)
  const AdFlowScaffold({super.key, required this.title, this.sub, this.step, this.right, this.children = const [], this.gap = 22, this.bottom, this.canPop = true, this.padding, this.bodyOverride});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(kAdPad, top + 8, kAdPad, 12),
              decoration: const BoxDecoration(color: Color(0xF2FAFBFD), border: Border(bottom: BorderSide(color: _line))),
              child: Column(children: [
                Row(children: [
                  if (canPop) ...[const JV2BackButton(), const SizedBox(width: 10)],
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: JV2.ink, letterSpacing: -0.2)),
                      if (sub != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub))),
                    ]),
                  ),
                  if (right != null) right!,
                ]),
                if (step != null) Padding(padding: const EdgeInsets.only(top: 13), child: JV2StepBar(step: step!, total: 4)),
              ]),
            ),
            Expanded(
              child: bodyOverride ??
                  SingleChildScrollView(
                    padding: padding ?? const EdgeInsets.fromLTRB(kAdPad, 20, kAdPad, 26),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
                    ]),
                  ),
            ),
            if (bottom != null)
              Container(
                padding: EdgeInsets.fromLTRB(kAdPad, 12, kAdPad, MediaQuery.paddingOf(context).bottom + 18),
                decoration: const BoxDecoration(color: Color(0xF5FAFBFD), border: Border(top: BorderSide(color: _line))),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// The footer's primary button, with the gold sparkle the design puts on AI actions.
class AdPrimary extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool spark, busy;
  const AdPrimary({super.key, required this.label, required this.onPressed, this.spark = false, this.busy = false});

  @override
  Widget build(BuildContext context) => JV2PrimaryButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: JV2.inkMute))
        : Row(mainAxisSize: MainAxisSize.min, children: [if (spark) ...[const AdSpark(size: 13, color: Color(0xFFE5C48F)), const SizedBox(width: 8)], Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis))]),
  );
}

/// A section label: "Ad summary  required".
class AdLabel extends StatelessWidget {
  final String text;
  final String? sub;
  const AdLabel(this.text, {super.key, this.sub});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: JV2.ink))),
      if (sub != null) ...[const SizedBox(width: 8), Flexible(child: Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: JV2.inkMute)))],
    ]),
  );
}

class AdHint extends StatelessWidget {
  final Widget child;
  AdHint(String text, {Key? key}) : child = Text(text, style: const TextStyle(fontSize: 11.5, height: 1.45, color: JV2.inkSub)), super(key: key);

  /// Text with **bold** parts, as the design's hints have.
  AdHint.markup(String text, {Key? key}) : child = Text.rich(TextSpan(children: _spans(text)), style: const TextStyle(fontSize: 11.5, height: 1.45, color: JV2.inkSub)), super(key: key);

  static List<InlineSpan> _spans(String text) {
    final parts = text.split('**');
    return [for (var i = 0; i < parts.length; i++) TextSpan(text: parts[i], style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700, color: JV2.ink) : null)];
  }

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 8), child: child);
}

/// White card with a hairline border and a small shadow.
class AdCard extends StatelessWidget {
  final List<Widget> children;
  final double radius;
  const AdCard({super.key, required this.children, this.radius = 16});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(radius), border: Border.all(color: _line), boxShadow: _shadowSm),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

/// Dashed outline (the design's "+ Choose a developer", "Upload images").
class AdDashed extends StatelessWidget {
  final double height, radius;
  final double? width;
  final Color color;
  final VoidCallback? onTap;
  final Widget child;
  const AdDashed({super.key, required this.height, required this.child, this.onTap, this.radius = 15, this.width, this.color = const Color(0x330B2A4A)});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: CustomPaint(
      painter: _DashPainter(radius, color),
      child: SizedBox(height: height, width: width ?? double.infinity, child: Center(child: child)),
    ),
  );
}

class _DashPainter extends CustomPainter {
  final double r;
  final Color color;
  const _DashPainter(this.r, this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0.75, 0.75, s.width - 1.5, s.height - 1.5), Radius.circular(r)));
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.r != r || o.color != color;
}

/// Choice chip (tone, language): navy when on.
class AdChoice extends StatelessWidget {
  final bool on;
  final String label;
  final VoidCallback onTap;
  const AdChoice({super.key, required this.on, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: on ? JV2.navy : JV2.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: on ? JV2.navy : _line)),
      child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: on ? Colors.white : JV2.ink)),
    ),
  );
}

/// The AI ad as it will be saved: photo, serif headline, subline and button, in the proportions of the chosen size.
class AdPreview extends StatelessWidget {
  final String? imageUrl, head, sub, cta;
  final double aspect; // width / height of the file
  const AdPreview({super.key, this.imageUrl, this.head, this.sub, this.cta, this.aspect = 1200 / 825});

  @override
  Widget build(BuildContext context) {
    final tall = aspect < 0.9;
    return AspectRatio(
      aspectRatio: aspect,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: JV2.shadowMd),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _Tint())
          else
            const _Tint(),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00081424), Color(0x00081424), Color(0xB8081424)], stops: [0, 0.35, 1]))),
          PositionedDirectional(
            start: 14,
            end: 14,
            bottom: 13,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(head ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: AdStyles.display(context, tall ? 20 : 22).copyWith(color: Colors.white, height: 1.1, letterSpacing: -0.2)),
                  if ((sub ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xD9FFFFFF)))),
                ]),
              ),
              if ((cta ?? '').isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(cta!, key: const Key('ad-preview-cta'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: JV2.navy)),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Tint extends StatelessWidget {
  const _Tint();
  @override
  Widget build(BuildContext context) => const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1), colors: [JV2.navyGlow, JV2.goldHi])));
}

/// "Facts in this ad": a tick, the fact, and where it came from.
class AdFactsUsed extends StatelessWidget {
  final List<AdFact> facts;
  final bool ar;
  const AdFactsUsed({super.key, required this.facts, required this.ar});

  @override
  Widget build(BuildContext context) => AdCard(radius: 14, children: [
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _line))),
      child: Text('adstudio.facts_in_ad'.tr().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: JV2.inkSub)),
    ),
    if (facts.isEmpty)
      Padding(padding: const EdgeInsets.all(13), child: Align(alignment: AlignmentDirectional.centerStart, child: Text('adstudio.no_facts_in_ad'.tr(), key: const Key('ad-no-facts-in-ad'), style: const TextStyle(fontSize: 12.5, color: JV2.inkSub))))
    else
      for (var i = 0; i < facts.length; i++)
        Container(
          key: Key('ad-used-${facts[i].key}'),
          decoration: BoxDecoration(border: Border(top: i == 0 ? BorderSide.none : const BorderSide(color: _line))),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(children: [
            const Icon(Icons.check_rounded, size: 14, color: JV2.success),
            const SizedBox(width: 10),
            Text(facts[i].label(ar), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: JV2.ink)),
            const SizedBox(width: 10),
            Expanded(child: Text(facts[i].detail(ar), textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub))),
          ]),
        ),
  ]);
}

/// A fact the admin can allow or not: checkbox, label, detail.
class AdFactCheckRow extends StatelessWidget {
  final AdFact fact;
  final bool ar, on;
  final VoidCallback onTap;
  const AdFactCheckRow({super.key, required this.fact, required this.ar, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: on ? JV2.navy : JV2.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: on ? JV2.navy : const Color(0x330B2A4A), width: 1.5)),
          child: on ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fact.label(ar), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: on ? JV2.ink : JV2.inkSub)),
            Padding(padding: const EdgeInsets.only(top: 2), child: Text(fact.detail(ar), style: const TextStyle(fontSize: 11.5, color: JV2.inkMute))),
          ]),
        ),
      ]),
    ),
  );
}

/// The developer's logo, or its initials in the serif face.
class AdLogoTile extends StatelessWidget {
  final String? url;
  final String initials;
  const AdLogoTile({super.key, this.url, required this.initials});

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: JV2.fillFaint, borderRadius: BorderRadius.circular(11), border: Border.all(color: _line)),
    alignment: Alignment.center,
    child: url != null
        ? Image.network(url!, width: 42, height: 42, fit: BoxFit.cover, errorBuilder: (_, _, _) => Text(initials, style: AdStyles.display(context, 16).copyWith(color: JV2.navy)))
        : Text(initials, style: AdStyles.display(context, 16).copyWith(color: JV2.navy)),
  );
}
