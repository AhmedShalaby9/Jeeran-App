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

/// What the property page shows under the price and title while the rest of the record loads:
/// the same blocks it will have (about, payment plan, details, seller), as soft moving placeholders.
class PropertyBodyShimmer extends StatelessWidget {
  const PropertyBodyShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9EEF4),
      highlightColor: const Color(0xFFF6F8FB),
      child: Padding(
        key: const Key('property-shimmer'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // about
            _box(14, w: 70, r: 5),
            const SizedBox(height: 12),
            _box(12, r: 5),
            const SizedBox(height: 8),
            _box(12, r: 5),
            const SizedBox(height: 8),
            _box(12, w: 220, r: 5),
            const SizedBox(height: 28),
            // payment plans: heading, chips, summary card
            _box(20, w: 150, r: 6),
            const SizedBox(height: 14),
            Row(
              children: [
                _box(40, w: 118, r: 12),
                const SizedBox(width: 8),
                _box(40, w: 118, r: 12),
                const SizedBox(width: 8),
                Expanded(child: _box(40, r: 12)),
              ],
            ),
            const SizedBox(height: 12),
            _box(190, r: 18),
            const SizedBox(height: 28),
            // details
            _box(20, w: 110, r: 6),
            const SizedBox(height: 14),
            for (var i = 0; i < 5; i++) ...[
              Row(
                children: [
                  _box(12, w: 96, r: 5),
                  const SizedBox(width: 24),
                  Expanded(child: _box(12, r: 5)),
                ],
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 12),
            // who's selling
            _box(86, r: 18),
          ],
        ),
      ),
    );
  }
}
