import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

enum PackagesCardState { unsubscribed, active, lowQuota }

class PackagesHomeCard extends StatelessWidget {
  final PackagesCardState state;
  const PackagesHomeCard({
    super.key,
    this.state = PackagesCardState.unsubscribed,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PackagesCardState.unsubscribed => const _UnsubCard(),
      PackagesCardState.active => const _ActiveCard(),
      PackagesCardState.lowQuota => const _LowCard(),
    };
  }
}

const _kGold = Color(0xFFB8893D);
const _kGoldSoft = Color(0xFFF5ECDB);
const _kInkSub = Color(0xFF5B6474);

// ── Unsubscribed ──────────────────────────────────────────────

class _UnsubCard extends StatelessWidget {
  const _UnsubCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2A4A), Color(0xFF1A4A80), Color(0xFF0A2A4A)],
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
                  colors: [_kGold.withValues(alpha: 0.22), const Color(0x00B8893D)],
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
                          // "Premium feature" pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _kGold.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _SparkIcon(
                                  size: 11,
                                  color: Color(0xFFF0C060),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'PREMIUM FEATURE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFF0C060),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start posting\nproperties',
                            style: TextStyle(
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
                    _BuildingIcon(size: 52),
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
                    onPressed: () {},
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
                        const _SparkIcon(size: 13, color: _kGold),
                        const SizedBox(width: 8),
                        const Text(
                          'View all plans',
                          style: TextStyle(
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: hot
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hot
                    ? _kGold.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$price',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'JOD/mo',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0x99FFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$ads ads',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xDDFFFFFF),
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
                    color: _kGold,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(
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

// ── Active subscription ───────────────────────────────────────

class _ActiveCard extends StatelessWidget {
  const _ActiveCard();

  @override
  Widget build(BuildContext context) {
    const used = 6;
    const total = 20;
    final pct = used / total;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2A4A), Color(0xFF1A4A80), Color(0xFF0A2A4A)],
          stops: [0, 0.6, 1],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kGold.withValues(alpha: 0.18), const Color(0x00B8893D)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF5DE0A5),
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'Growth plan · Active',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xBFFFFFFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '$used of $total listings used',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '${total - used}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'left',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF5DE0A5)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Renews in 12 days',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    Text(
                      '49 JOD/mo',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _CardButton(
                        label: 'New listing',
                        icon: Icons.add_rounded,
                        onTap: () {},
                        style: _CardButtonStyle.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CardButton(
                      label: 'Details',
                      icon: Icons.access_time_rounded,
                      onTap: () {},
                      style: _CardButtonStyle.ghost,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Low quota ─────────────────────────────────────────────────

class _LowCard extends StatelessWidget {
  const _LowCard();

  @override
  Widget build(BuildContext context) {
    const used = 18;
    const total = 20;
    final pct = used / total;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A1A1A), Color(0xFF7A2E1A), Color(0xFF3A1010)],
          stops: [0, 0.6, 1],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDC503C).withValues(alpha: 0.22),
                    const Color(0x00DC503C),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFF6B4A),
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'Growth plan · Running low',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xB3FFFFFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Only ${total - used} listings left',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FF5032),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x66FF5032)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '${total - used}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF8066),
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'left',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF4A2A)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$used/$total listings used',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      'Renews in 12 days',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _CardButton(
                        label: 'Upgrade plan',
                        icon: Icons.auto_awesome_rounded,
                        onTap: () {},
                        style: _CardButtonStyle.whiteRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CardButton(
                      label: 'Buy more',
                      onTap: () {},
                      style: _CardButtonStyle.ghost,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card button ────────────────────────────────────────

enum _CardButtonStyle { white, whiteRed, ghost }

class _CardButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final _CardButtonStyle style;
  const _CardButton({
    required this.label,
    required this.onTap,
    required this.style,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isGhost = style == _CardButtonStyle.ghost;
    final bg = switch (style) {
      _CardButtonStyle.white => Colors.white,
      _CardButtonStyle.whiteRed => Colors.white,
      _CardButtonStyle.ghost => Colors.white.withValues(alpha: 0.1),
    };
    final fg = switch (style) {
      _CardButtonStyle.white => AppColors.primary,
      _CardButtonStyle.whiteRed => const Color(0xFF7A2E1A),
      _CardButtonStyle.ghost => Colors.white,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: EdgeInsets.symmetric(horizontal: isGhost ? 14 : 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isGhost
              ? Border.all(color: Colors.white.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Misc ──────────────────────────────────────────────────────

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
      Icon(Icons.business_rounded, size: size, color: Color(0x2EFFFFFF));
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
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
