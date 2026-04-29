import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/property_widgets.dart';

class PropertyImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const PropertyImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<PropertyImageViewerPage> createState() =>
      _PropertyImageViewerPageState();
}

class _PropertyImageViewerPageState extends State<PropertyImageViewerPage> {
  late int _current;
  late final PageController _pageController;
  late final ScrollController _thumbController;

  static const double _thumbW = 58.0;
  static const double _thumbH = 72.0;
  static const double _thumbGap = 8.0;
  static const double _stripH = _thumbH + 32; // padding above + safe area below

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbController = ScrollController(
      initialScrollOffset: _thumbScrollOffset(widget.initialIndex),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  // Scroll so the active thumb is centered in the strip
  double _thumbScrollOffset(int index) {
    const itemW = _thumbW + _thumbGap;
    final screenW = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.width /
        WidgetsBinding
            .instance.platformDispatcher.views.first.devicePixelRatio;
    final target = index * itemW - (screenW / 2) + (_thumbW / 2);
    return target.clamp(0.0, double.maxFinite);
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    final offset = _thumbScrollOffset(i);
    if (_thumbController.hasClients) {
      _thumbController.animateTo(
        offset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  void _jumpTo(int i) {
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Main swipeable image ──────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: _stripH + bottomPad,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) => InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[i],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white30,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (_, __, ___) => const PropertyPlaceholder(),
                  ),
                ),
              ),
            ),

            // ── Top bar ───────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Counter badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_current + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 38), // balance
                  ],
                ),
              ),
            ),

            // ── Thumbnail strip ───────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _stripH + bottomPad,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
                child: ListView.separated(
                  controller: _thumbController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.images.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: _thumbGap),
                  itemBuilder: (_, i) {
                    final active = i == _current;
                    return GestureDetector(
                      onTap: () => _jumpTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: _thumbW,
                        height: _thumbH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                            width: active ? 2.5 : 1.5,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: CachedNetworkImage(
                          imageUrl: widget.images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.white10),
                          errorWidget: (_, __, ___) =>
                              Container(color: Colors.white10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
