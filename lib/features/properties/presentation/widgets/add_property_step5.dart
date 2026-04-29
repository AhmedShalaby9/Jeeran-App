import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'add_property_form.dart';

class AddPropertyStep5 extends StatelessWidget {
  final AddPropertyForm form;

  const AddPropertyStep5({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review your listing',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Confirm everything looks right, then publish.',
          style: TextStyle(fontSize: 15, color: AppColors.inkSub, height: 1.4),
        ),
        const SizedBox(height: 24),

        // ── Preview card ─────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // photo placeholder
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: const Color(0xFFD7DDE5),
                    child: form.photoCount > 0
                        ? CustomPaint(painter: _CheckerPainter())
                        : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 36,
                              color: Color(0xFF9AA5B4),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        form.purpose.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.price.isNotEmpty
                          ? '${_formatNumber(form.price)} EGP'
                          : '— EGP',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      form.title.isNotEmpty ? form.title : 'Untitled listing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkSub,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.bed_outlined,
                          value: '${form.bedrooms}',
                        ),
                        const SizedBox(width: 14),
                        _MiniStat(
                          icon: Icons.bathtub_outlined,
                          value: '${form.bathrooms}',
                        ),
                        const SizedBox(width: 14),
                        _MiniStat(
                          icon: Icons.square_foot_outlined,
                          value: form.size.isNotEmpty
                              ? '${form.size} m²'
                              : '— m²',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Details table ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              _ReviewRow(
                label: 'Type',
                value: _capitalize(form.propertyType),
              ),
              _ReviewRow(label: 'Purpose', value: form.purpose),
              _ReviewRow(
                label: 'Location',
                value: [form.area, form.city]
                    .where((s) => s.isNotEmpty)
                    .join(', '),
              ),
              _ReviewRow(
                label: 'Furnishing',
                value: form.furnishing ?? '—',
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Photos summary ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: _ReviewRow(
            label: 'Photos',
            value: '${form.photoCount} added',
            last: true,
          ),
        ),
        const SizedBox(height: 16),

        // ── Quota banner ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Center(
                  child: Text(
                    '14',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '14 listings remaining this month',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Growth plan · renews May 18',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(String raw) {
    final n = double.tryParse(raw);
    if (n == null) return raw;
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(0)}K';
    }
    return raw;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Helper widgets ────────────────────────────────────────────

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _ReviewRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(
              bottom: BorderSide(color: AppColors.hairline),
            ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.inkSub),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.inkSub),
      const SizedBox(width: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 12, color: AppColors.inkSub),
      ),
    ],
  );
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 14.0;
    final light = Paint()..color = const Color(0xFFD7DDE5);
    final dark = Paint()..color = const Color(0xFFCDD4DD);
    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final isDark = ((x / tileSize).floor() + (y / tileSize).floor()).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          isDark ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
