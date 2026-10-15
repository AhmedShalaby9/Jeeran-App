import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget _box(double h, {double? w, double r = 14, Color color = Colors.white}) => Container(
  height: h,
  width: w,
  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
);

Widget _shimmer(Widget child) => Shimmer.fromColors(
  baseColor: const Color(0xFFE9EEF4),
  highlightColor: const Color(0xFFF6F8FB),
  child: child,
);

/// Placeholder rows shaped like the all-compounds rows (photo, name, developer · area, price line).
class CompoundRowShimmer extends StatelessWidget {
  final int rows;
  const CompoundRowShimmer({super.key, this.rows = 8});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Column(
        key: const Key('compound-shimmer'),
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    _box(60, w: 72, r: 11),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(13, w: 130 + (i % 3) * 28, r: 5),
                          const SizedBox(height: 7),
                          _box(11, w: 170 + (i % 2) * 24, r: 5),
                          const SizedBox(height: 8),
                          _box(11, w: 110, r: 5),
                        ],
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

/// Placeholder for the wide launch / offer compound cards (a big photo and a line of text under it).
class LaunchCardShimmer extends StatelessWidget {
  final int count;
  const LaunchCardShimmer({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Column(
        key: const Key('launch-shimmer'),
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 188, color: const Color(0xFFE9EEF4)),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          _box(44, w: 44, r: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _box(14, w: 150, r: 5),
                                const SizedBox(height: 8),
                                _box(11, w: 110, r: 5),
                              ],
                            ),
                          ),
                        ],
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

/// Placeholder for the unit cards of the launches / offers list (photo, price, title, facts).
class UnitCardShimmer extends StatelessWidget {
  final int count;
  const UnitCardShimmer({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Column(
        key: const Key('unit-shimmer'),
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 120, color: const Color(0xFFE9EEF4)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(19, w: 120, r: 6),
                          const SizedBox(height: 9),
                          _box(13, r: 5),
                          const SizedBox(height: 8),
                          _box(11, w: 180, r: 5),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _box(12, w: 54, r: 5),
                              const SizedBox(width: 10),
                              _box(12, w: 54, r: 5),
                              const SizedBox(width: 10),
                              _box(12, w: 70, r: 5),
                            ],
                          ),
                        ],
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

/// Search → "Top developers" rail while it loads: cards shaped like `DevRailCard` (cover strip, logo, name, line).
class DevRailShimmer extends StatelessWidget {
  const DevRailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      ListView.separated(
        key: const Key('dev-rail-shimmer'),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 11),
        itemBuilder: (_, i) => Container(
          width: 132,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              Container(height: 62, color: const Color(0xFFE9EEF4)),
              const SizedBox(height: 12),
              _box(46, w: 46, r: 14),
              const SizedBox(height: 12),
              _box(12, w: 76 + (i % 2) * 18, r: 5),
              const SizedBox(height: 8),
              _box(10, w: 54, r: 5),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search → "Launches and offers" rail while it loads: tall photo cards like the real ones.
class PromoRailShimmer extends StatelessWidget {
  const PromoRailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      ListView.separated(
        key: const Key('promo-rail-shimmer'),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Container(
          width: 195,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _box(20, w: 62, r: 999, color: const Color(0xFFE9EEF4)),
              const Spacer(),
              _box(14, w: 120, r: 5, color: const Color(0xFFE9EEF4)),
              const SizedBox(height: 8),
              _box(11, w: 80, r: 5, color: const Color(0xFFE9EEF4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search results while they load: rows shaped like `UnitRow` (square photo, price, title, facts).
class UnitRowShimmer extends StatelessWidget {
  final int rows;
  const UnitRowShimmer({super.key, this.rows = 4});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Column(
        key: const Key('results-shimmer'),
        children: [
          for (var i = 0; i < rows; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  _box(104, w: 104, r: 12, color: const Color(0xFFE9EEF4)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(17, w: 120, r: 5, color: const Color(0xFFE9EEF4)),
                        const SizedBox(height: 9),
                        _box(11, r: 5, color: const Color(0xFFE9EEF4)),
                        const SizedBox(height: 9),
                        _box(11, w: 110, r: 5, color: const Color(0xFFE9EEF4)),
                        const SizedBox(height: 13),
                        _box(11, w: 150, r: 5, color: const Color(0xFFE9EEF4)),
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
