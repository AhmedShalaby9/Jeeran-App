import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import '../../presentation/pages/plans_page.dart';

class UpgradePromoCard extends StatelessWidget {
  const UpgradePromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.promoGradientMid,
            AppColors.primary,
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // radial gold glow
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.22),
                    AppColors.gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // grid texture
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
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
                          // Premium feature pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SparkIcon(
                                  size: 11,
                                  color: AppColors.promoLightGold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'PREMIUM FEATURE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.promoLightGold,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'plans.promo_title'.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _BuildingIcon(size: 52),
                  ],
                ),
                const SizedBox(height: 14),
                // Plan pills
                Row(
                  children: [
                    _PlanPill(name: 'Starter', price: 19, ads: 5),
                    const SizedBox(width: 8),
                    _PlanPill(name: 'Growth', price: 49, ads: 20, hot: true),
                    const SizedBox(width: 8),
                    _PlanPill(name: 'Pro', price: 99, ads: 60),
                  ],
                ),
                const SizedBox(height: 16),
                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlansPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SparkIcon(size: 13, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Text(
                          'plans.view_all'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
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

class _PlanPill extends StatelessWidget {
  final String name;
  final int price;
  final int ads;
  final bool hot;

  const _PlanPill({
    required this.name,
    required this.price,
    required this.ads,
    this.hot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: hot
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hot
                    ? AppColors.gold.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '\$price',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${'currency'.tr()}/mo',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ' ads',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (hot)
            Positioned(
              top: -7,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'plans.popular'.tr(),
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SparkIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _SparkIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.auto_awesome_rounded, size: size, color: color);
}

class _BuildingIcon extends StatelessWidget {
  final double size;

  const _BuildingIcon({required this.size});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.business_rounded, size: size, color: Colors.white24);
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
