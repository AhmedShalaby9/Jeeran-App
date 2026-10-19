import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/jv2.dart';

const _softShadow = [BoxShadow(color: Color(0x0D0B2A4A), blurRadius: 2, offset: Offset(0, 1))];

/// "Master plan" and "Gallery", side by side under the key figures (design D3).
class MediaTiles extends StatelessWidget {
  final int photos;
  final bool hasPlan;
  final VoidCallback? onPlan;
  final VoidCallback? onGallery;
  const MediaTiles({super.key, required this.photos, required this.hasPlan, this.onPlan, this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tile(
            key: const Key('tile-plan'),
            icon: const _PlanGlyph(),
            title: 'compound.master_plan'.tr(),
            sub: hasPlan ? 'compound.tap_to_zoom'.tr() : 'compound.not_published'.tr(),
            onTap: hasPlan ? onPlan : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Tile(
            key: const Key('tile-gallery'),
            icon: const _GalleryGlyph(),
            title: 'compound.gallery'.tr(),
            sub: 'compound.n_photos'.plural(photos),
            onTap: photos > 0 ? onGallery : null,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final Widget icon;
  final String title, sub;
  final VoidCallback? onTap;
  const _Tile({super.key, required this.icon, required this.title, required this.sub, this.onTap});

  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    return Opacity(
      opacity: off ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JV2.line),
            boxShadow: off ? null : _softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: const Color(0x0F0B2A4A), borderRadius: BorderRadius.circular(11)),
                child: Center(child: icon),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: JV2.ink)),
                    const SizedBox(height: 1),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryGlyph extends StatelessWidget {
  const _GalleryGlyph();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(22, 22), painter: _GlyphPainter(gallery: true));
}

class _PlanGlyph extends StatelessWidget {
  const _PlanGlyph();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(22, 22), painter: _GlyphPainter(gallery: false));
}

/// The two line icons of the design, drawn on a 24×24 grid.
class _GlyphPainter extends CustomPainter {
  final bool gallery;
  _GlyphPainter({required this.gallery});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = JV2.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeJoin = StrokeJoin.round;
    if (gallery) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 4, 18, 16), const Radius.circular(3.5)), p);
      canvas.drawCircle(const Offset(9, 9.5), 1.8, p);
      canvas.drawPath(
        Path()
          ..moveTo(3.5, 17)
          ..lineTo(8.5, 12.5)
          ..lineTo(12, 15.5)
          ..lineTo(15, 13)
          ..lineTo(20.5, 17.5),
        p,
      );
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 3.5, 18, 17), const Radius.circular(3)), p);
      canvas.drawPath(
        Path()
          ..moveTo(3, 10)
          ..lineTo(10, 10)
          ..lineTo(10, 3.5)
          ..moveTo(10, 14)
          ..lineTo(21, 14)
          ..moveTo(14, 14)
          ..lineTo(14, 20.5),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => false;
}

/// The location card (design D3): a map, the area, and a "Directions" cue.
/// Tapping it opens the full map screen.
class MapCard extends StatelessWidget {
  final String area;
  final VoidCallback? onTap;
  const MapCard({super.key, required this.area, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: _card());

  Widget _card() {
    return Container(
      key: const Key('map-card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JV2.line),
        boxShadow: _softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const MapCanvas(),
                PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(11), boxShadow: _softShadow),
                    child: const Icon(Icons.open_in_full_rounded, size: 14, color: JV2.ink),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(area, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: JV2.ink)),
                      const SizedBox(height: 2),
                      Text('compound.location'.tr(), style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
                    ],
                  ),
                ),
                Text('compound.directions'.tr(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: JV2.navy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A drawn street map (parks, water, roads) with the pin in the middle, as in the design.
class MapCanvas extends StatelessWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth, h = c.maxHeight;
        Widget blob(double l, double t, double bw, double bh, Color color, {double radius = 999}) =>
            Positioned(left: l, top: t, width: bw, height: bh, child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius))));
        return Container(
          color: const Color(0xFFEEF1EC),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              blob(-0.10 * w, 0.58 * h, 0.75 * w, 0.60 * h, const Color(0xFFF4ECD4)),
              blob(0.62 * w, -0.20 * h, 0.50 * w, 0.55 * h, const Color(0xFFDDEBD9)),
              Positioned(left: 0, right: 0, top: 0.42 * h, height: 5, child: const ColoredBox(color: Color(0xFFF2C38B))),
              Positioned(left: 0.24 * w, top: 0, bottom: 0, width: 4, child: const ColoredBox(color: Color(0xFFF5D77E))),
              Positioned(
                left: 0.48 * w,
                top: -0.10 * h,
                width: 4,
                height: 1.4 * h,
                child: Transform.rotate(angle: 28 * 3.1415926 / 180, child: const ColoredBox(color: Colors.white)),
              ),
              Positioned(
                left: -0.05 * w,
                top: 0.75 * h,
                width: 1.2 * w,
                height: 3,
                child: Transform.rotate(angle: -6 * 3.1415926 / 180, child: const ColoredBox(color: Colors.white)),
              ),
              Positioned(left: w / 2 - 15, top: h / 2 - 37, child: const _Pin()),
            ],
          ),
        );
      },
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(30, 37.5), painter: _PinPainter());
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 30);
    final body = Path()
      ..moveTo(12, 29)
      ..cubicTo(12, 29, 21, 19.4, 21, 12)
      ..arcToPoint(const Offset(3, 12), radius: const Radius.circular(9), clockwise: false)
      ..cubicTo(3, 19.4, 12, 29, 12, 29)
      ..close();
    canvas.drawPath(body, Paint()..color = JV2.navy);
    canvas.drawCircle(const Offset(12, 12), 3.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PinPainter old) => false;
}
