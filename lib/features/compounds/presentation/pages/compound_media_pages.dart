import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/jv2.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart' show Photo;

Future<T?> _openFull<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(PageRouteBuilder<T>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ));

void openGallery(BuildContext context, {required String name, required List<String> images}) =>
    _openFull(context, CompoundGalleryPage(name: name, images: images));

void openPhotos(BuildContext context, {required String name, required List<String> images, int index = 0}) =>
    _openFull(context, PhotoPagerPage(name: name, images: images, index: index));

void openMasterPlan(BuildContext context, {required String name, required String url}) =>
    _openFull(context, MasterPlanPage(name: name, url: url));

/// Title bar of the viewers: a close button, the title and a line under it.
class _ViewerTop extends StatelessWidget {
  final String title, sub;
  final bool dark;
  const _ViewerTop({required this.title, required this.sub, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final c = dark ? Colors.white : JV2.ink;
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 12),
      decoration: BoxDecoration(
        color: dark ? Colors.transparent : const Color(0xF5FAFBFD),
        border: dark ? null : const Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('viewer-close'),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: dark ? const Color(0x1FFFFFFF) : JV2.surface,
                borderRadius: BorderRadius.circular(13),
                border: dark ? null : Border.all(color: JV2.line),
              ),
              child: Icon(Icons.close_rounded, size: 18, color: c),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c)),
                if (sub.isNotEmpty)
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: dark ? const Color(0xA6FFFFFF) : JV2.inkSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every photo of the compound in a two-column grid (every third one runs full width). Tap one to open it large.
class CompoundGalleryPage extends StatelessWidget {
  final String name;
  final List<String> images;
  const CompoundGalleryPage({super.key, required this.name, required this.images});

  @override
  Widget build(BuildContext context) {
    // rows: a wide photo, then two side by side, repeating
    final rows = <List<int>>[];
    for (var i = 0; i < images.length;) {
      if (i % 3 == 0) {
        rows.add([i++]);
      } else {
        rows.add([i, if (i + 1 < images.length) i + 1]);
        i += 2;
      }
    }
    Widget tile(int i, double h) => GestureDetector(
      key: Key('gallery-photo-$i'),
      onTap: () => openPhotos(context, name: name, images: images, index: i),
      child: Photo(url: images[i], height: h, radius: 14),
    );
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          _ViewerTop(title: 'compound.gallery'.tr(), sub: '$name · ${'compound.n_photos'.plural(images.length)}'),
          Expanded(
            child: ListView(
              key: const Key('gallery-grid'),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
              children: [
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: r.length == 1
                        ? tile(r.first, 200)
                        : Row(
                            children: [
                              Expanded(child: tile(r[0], 130)),
                              const SizedBox(width: 8),
                              Expanded(child: tile(r[1], 130)),
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

/// One photo at a time on black: swipe between them, pinch to zoom.
class PhotoPagerPage extends StatefulWidget {
  final String name;
  final List<String> images;
  final int index;
  const PhotoPagerPage({super.key, required this.name, required this.images, this.index = 0});

  @override
  State<PhotoPagerPage> createState() => _PhotoPagerPageState();
}

class _PhotoPagerPageState extends State<PhotoPagerPage> {
  late final PageController _page = PageController(initialPage: widget.index);
  late int _at = widget.index;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1726),
      body: Stack(
        children: [
          PageView.builder(
            key: const Key('photo-pager'),
            controller: _page,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _at = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: _NetImage(widget.images[i], fit: BoxFit.contain)),
            ),
          ),
          Positioned(left: 0, right: 0, top: 0, child: _ViewerTop(title: widget.name, sub: '${_at + 1} / ${widget.images.length}', dark: true)),
        ],
      ),
    );
  }
}

/// The master plan image, zoomable (pinch, double tap, or the + / − buttons).
class MasterPlanPage extends StatefulWidget {
  final String name, url;
  const MasterPlanPage({super.key, required this.name, required this.url});

  @override
  State<MasterPlanPage> createState() => _MasterPlanPageState();
}

class _MasterPlanPageState extends State<MasterPlanPage> with SingleTickerProviderStateMixin {
  final _ctl = TransformationController();
  static const _min = 1.0, _max = 6.0;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  double get _scale => _ctl.value.getMaxScaleOnAxis();

  /// Zoom around the middle of the picture.
  void _zoom(double factor) {
    final target = (_scale * factor).clamp(_min, _max);
    final k = target / _scale;
    final box = context.findRenderObject() as RenderBox?;
    final c = box == null ? Offset.zero : Offset(box.size.width / 2, box.size.height / 2);
    final m = _ctl.value.clone()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(k, k, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
    setState(() => _ctl.value = m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1726),
      body: Column(
        children: [
          _ViewerTop(title: 'compound.master_plan'.tr(), sub: widget.name, dark: true),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: const Color(0xFFF6F8FB), borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  GestureDetector(
                    onDoubleTap: () => _zoom(_scale > 1.5 ? 1 / _scale : 2.5),
                    child: InteractiveViewer(
                      key: const Key('plan-zoom'),
                      transformationController: _ctl,
                      minScale: _min,
                      maxScale: _max,
                      child: SizedBox.expand(child: _NetImage(widget.url, fit: BoxFit.contain)),
                    ),
                  ),
                  PositionedDirectional(
                    end: 12,
                    bottom: 12,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: JV2.shadowMd),
                      child: Column(
                        children: [
                          _ZoomBtn(key: const Key('plan-zoom-in'), icon: Icons.add_rounded, onTap: () => _zoom(1.6)),
                          const Divider(height: 1, color: JV2.line),
                          _ZoomBtn(key: const Key('plan-zoom-out'), icon: Icons.remove_rounded, onTap: () => _zoom(1 / 1.6)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: JV2.ink)),
  );
}

/// A network image that says it is loading and says when it could not load.
class _NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const _NetImage(this.url, {this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, p) => p == null
          ? child
          : const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.2, color: JV2.goldHi))),
      errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 34, color: JV2.inkMute)),
    );
  }
}
