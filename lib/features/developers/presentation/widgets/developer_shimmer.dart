import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget _box(double h, {double? w, double r = 14}) => Container(
  height: h,
  width: w,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(r),
  ),
);

Widget _shimmer(Widget child) => Shimmer.fromColors(
  baseColor: const Color(0xFFE9EEF4),
  highlightColor: const Color(0xFFF6F8FB),
  child: child,
);

/// Placeholder rows shaped like `DevListRow` while the developers list loads.
class DevListShimmer extends StatelessWidget {
  final int rows;
  const DevListShimmer({super.key, this.rows = 8});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Column(
        key: const Key('dev-shimmer'),
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _box(46, w: 46, r: 14),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(13, w: 120 + (i % 3) * 30, r: 5),
                          const SizedBox(height: 8),
                          _box(10, w: 90, r: 5),
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

/// Placeholder for a developer page body: stats, Ask card, tabs and compound rows.
class DeveloperBodyShimmer extends StatelessWidget {
  const DeveloperBodyShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Padding(
        key: const Key('developer-shimmer'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            _box(64, r: 16),
            const SizedBox(height: 16),
            _box(60, r: 16),
            const SizedBox(height: 16),
            _box(56, r: 16),
            const SizedBox(height: 24),
            Row(
              children: [
                _box(14, w: 70, r: 5),
                const SizedBox(width: 20),
                _box(14, w: 60, r: 5),
                const SizedBox(width: 20),
                _box(14, w: 50, r: 5),
              ],
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < 3; i++) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _box(82, w: 82, r: 13),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(10, w: 60, r: 5),
                          const SizedBox(height: 9),
                          _box(14, w: 150, r: 5),
                          const SizedBox(height: 9),
                          _box(10, w: 100, r: 5),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
