import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../ai_ads/presentation/pages/ai_ads_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../properties/presentation/pages/add_property_page.dart';
import '../../../seller_request/presentation/bloc/seller_request_bloc.dart';
import '../../../seller_request/presentation/bloc/seller_request_event.dart';
import '../../../seller_request/presentation/bloc/seller_request_state.dart';

// ── Position router ───────────────────────────────────────────────────────────

class PromoBannerAtPosition extends StatelessWidget {
  final int position;
  const PromoBannerAtPosition({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    if (AppStorage.isAdmin) return const SizedBox.shrink();

    final banners = AppSettingsService.instance.promoBannersOrdered;
    if (position >= banners.length) return const SizedBox.shrink();

    final type = banners[position];
    final delay = Duration(milliseconds: position * 120);

    // Subscription check — AuthBloc is provided by MainPage above.
    final isSeller = AppStorage.isSeller;
    bool hasSubscription = false;
    if (isSeller) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthMeLoaded) {
        hasSubscription = authState.user.subscriptionId != null;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (type == 'ai_ads')
          _AiAdsBanner(
            onTap: () => AiAdsPage.push(context),
            riseDelay: delay,
          )
        else
          _SellerBanner(
            isSeller: isSeller,
            hasSubscription: hasSubscription,
            riseDelay: delay,
          ),
      ],
    );
  }
}

// ── AI Ads banner ─────────────────────────────────────────────────────────────

class _AiAdsBanner extends StatelessWidget {
  final VoidCallback onTap;
  final Duration riseDelay;
  const _AiAdsBanner({required this.onTap, required this.riseDelay});

  @override
  Widget build(BuildContext context) {
    return _PromoBannerCard(
      onTap: onTap,
      riseDelay: riseDelay,
      gradientColors: const [Color(0xFF0E1726), Color(0xFF1A4A80), Color(0xFF25ADDE)],
      gradientStops: const [0.0, 0.52, 1.0],
      glowColor: const Color(0x8C25ADDE),
      particleColor: const Color(0x4025ADDE),
      icon: Icons.auto_awesome_rounded,
      title: 'home.promo_ai_ads_title'.tr(),
      subtitle: 'home.promo_ai_ads_subtitle'.tr(),
    );
  }
}

// ── Seller banner — three cases ───────────────────────────────────────────────
//
//  Case 1 · buyer/guest → submit seller request via API (inline, no navigation)
//  Case 2 · seller, no active subscription → switch to packages tab (index 3)
//  Case 3 · seller with active subscription → open Add Property wizard

class _SellerBanner extends StatelessWidget {
  final bool isSeller;
  final bool hasSubscription;
  final Duration riseDelay;

  const _SellerBanner({
    required this.isSeller,
    required this.hasSubscription,
    required this.riseDelay,
  });

  @override
  Widget build(BuildContext context) {
    // Case 1: not a seller — needs its own SellerRequestBloc to call the API
    if (!isSeller) {
      return BlocProvider(
        create: (_) => sl<SellerRequestBloc>(),
        child: _SellerRequestBannerBody(riseDelay: riseDelay),
      );
    }

    // Case 2: seller with no active subscription
    if (!hasSubscription) {
      return _PromoBannerCard(
        onTap: () => MainPage.switchTab(3),
        riseDelay: riseDelay,
        gradientColors: const [Color(0xFF3D2200), Color(0xFF7F5C1F), Color(0xFFB8893D)],
        gradientStops: const [0.0, 0.52, 1.0],
        glowColor: const Color(0x99B8893D),
        particleColor: const Color(0x50B8893D),
        icon: Icons.workspace_premium_rounded,
        title: 'home.promo_get_subscription_title'.tr(),
        subtitle: 'home.promo_get_subscription_subtitle'.tr(),
      );
    }

    // Case 3: seller with active subscription
    return _PromoBannerCard(
      onTap: () => AddPropertyPage.push(context),
      riseDelay: riseDelay,
      gradientColors: const [Color(0xFF3D2200), Color(0xFF7F5C1F), Color(0xFFB8893D)],
      gradientStops: const [0.0, 0.52, 1.0],
      glowColor: const Color(0x99B8893D),
      particleColor: const Color(0x50B8893D),
      icon: Icons.add_home_rounded,
      title: 'home.promo_add_property_title'.tr(),
      subtitle: 'home.promo_add_property_subtitle'.tr(),
    );
  }
}

// ── Case 1 body: buyer submits seller request inline ─────────────────────────

class _SellerRequestBannerBody extends StatelessWidget {
  final Duration riseDelay;
  const _SellerRequestBannerBody({required this.riseDelay});

  void _onTap(BuildContext context) {
    context.read<SellerRequestBloc>().add(const SubmitSellerRequestEvent());
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Lottie.asset(
                'assets/animations/success.json',
                width: 140, height: 140,
                repeat: false,
              ),
              const SizedBox(height: 4),
              Text(
                'seller_request.success_title'.tr(),
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.ink, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'seller_request.success_message'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.inkSub,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tagPrimaryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 16, color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'seller_request.approval_note'.tr(),
                        style: const TextStyle(
                          fontSize: 13, color: AppColors.inkSub, height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'seller_request.got_it'.tr(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SellerRequestBloc, SellerRequestState>(
      listener: (context, state) {
        if (state is SellerRequestSuccess) {
          _showSuccessSheet(context);
        }
      },
      builder: (context, state) {
        final isLoading = state is SellerRequestLoading;
        return _PromoBannerCard(
          onTap: isLoading ? () {} : () => _onTap(context),
          riseDelay: riseDelay,
          isLoading: isLoading,
          gradientColors: const [Color(0xFF3D2200), Color(0xFF7F5C1F), Color(0xFFB8893D)],
          gradientStops: const [0.0, 0.52, 1.0],
          glowColor: const Color(0x99B8893D),
          particleColor: const Color(0x50B8893D),
          icon: Icons.storefront_rounded,
          title: 'home.promo_seller_title'.tr(),
          subtitle: 'home.promo_seller_subtitle'.tr(),
        );
      },
    );
  }
}

// ── Animated card ─────────────────────────────────────────────────────────────

class _PromoBannerCard extends StatefulWidget {
  final VoidCallback onTap;
  final Duration riseDelay;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final Color glowColor;
  final Color particleColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;

  const _PromoBannerCard({
    required this.onTap,
    required this.riseDelay,
    required this.gradientColors,
    required this.gradientStops,
    required this.glowColor,
    required this.particleColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
  });

  @override
  State<_PromoBannerCard> createState() => _PromoBannerCardState();
}

class _PromoBannerCardState extends State<_PromoBannerCard>
    with TickerProviderStateMixin {
  late final AnimationController _riseCtrl;
  late final AnimationController _orbCtrl;
  late final AnimationController _shineCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _nudgeCtrl;
  late final AnimationController _particleCtrl;

  late final Animation<double> _riseOpacity;
  late final Animation<double> _riseY;
  late final Animation<double> _orbTx;
  late final Animation<double> _orbTy;
  late final Animation<double> _orbScale;
  late final Animation<double> _floatY;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _pulseScale;
  late final Animation<double> _nudgeX;

  static const _particles = [
    [0.06, 0.25, 2.0, 0.00],
    [0.16, 0.72, 1.4, 0.28],
    [0.27, 0.18, 2.4, 0.57],
    [0.39, 0.80, 1.8, 0.85],
    [0.52, 0.38, 2.0, 1.13],
    [0.63, 0.62, 1.4, 1.42],
    [0.74, 0.22, 2.2, 1.70],
    [0.84, 0.75, 1.6, 1.99],
    [0.33, 0.50, 1.4, 2.27],
    [0.70, 0.42, 2.0, 2.55],
    [0.91, 0.30, 1.6, 2.83],
  ];

  @override
  void initState() {
    super.initState();

    _riseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _riseOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _riseCtrl, curve: const Cubic(0.2, 0.7, 0.3, 1)));
    _riseY = Tween<double>(begin: 10, end: 0).animate(
        CurvedAnimation(parent: _riseCtrl, curve: const Cubic(0.2, 0.7, 0.3, 1)));
    Future.delayed(widget.riseDelay, () { if (mounted) _riseCtrl.forward(); });

    _orbCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))
      ..repeat(reverse: true);
    _orbTx = Tween<double>(begin: 0, end: -14).animate(
        CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut));
    _orbTy = Tween<double>(begin: 0, end: 8).animate(
        CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut));
    _orbScale = Tween<double>(begin: 1, end: 1.15).animate(
        CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut));

    _shineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))
      ..repeat();

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
    _floatY = Tween<double>(begin: 0, end: -3).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.9).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseScale = Tween<double>(begin: 1, end: 1.12).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _nudgeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _nudgeX = Tween<double>(begin: 0, end: 4).animate(
        CurvedAnimation(parent: _nudgeCtrl, curve: Curves.easeInOut));

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat();
  }

  @override
  void dispose() {
    _riseCtrl.dispose();
    _orbCtrl.dispose();
    _shineCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _nudgeCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: const Alignment(-1.0, -0.18),
      end: const Alignment(1.0, 0.18),
      colors: widget.gradientColors,
      stops: widget.gradientStops,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([
        _riseCtrl, _orbCtrl, _shineCtrl,
        _floatCtrl, _pulseCtrl, _nudgeCtrl, _particleCtrl,
      ]),
      builder: (context, _) {
        return Opacity(
          opacity: _riseOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _riseY.value),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: Colors.white.withValues(alpha: 0.08),
                highlightColor: Colors.white.withValues(alpha: 0.05),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final shineProgress = CurvedAnimation(
                      parent: _shineCtrl,
                      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
                    ).value;
                    final shineX = -80.0 + (w + 160) * shineProgress;

                    return ClipRect(
                      child: SizedBox(
                        height: 92,
                        child: Stack(
                          children: [
                            // 1 ── Gradient background
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(gradient: gradient),
                              ),
                            ),

                            // 2 ── Floating orb glow
                            Positioned(
                              top: -38, right: w * 0.06,
                              child: Transform.translate(
                                offset: Offset(_orbTx.value, _orbTy.value),
                                child: Transform.scale(
                                  scale: _orbScale.value,
                                  child: Container(
                                    width: 160, height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [widget.glowColor, Colors.transparent],
                                        stops: const [0.0, 0.68],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 3 ── Grid texture
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.06,
                                child: CustomPaint(painter: _GridPainter()),
                              ),
                            ),

                            // 4 ── Floating particles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ParticlePainter(
                                  t: _particleCtrl.value,
                                  baseColor: widget.particleColor,
                                  particles: _particles,
                                ),
                              ),
                            ),

                            // 5 ── Shine sweep
                            Positioned(
                              top: 0, bottom: 0, left: shineX, width: 60,
                              child: Transform(
                                transform: Matrix4.skewX(-0.32),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 6 ── Content row
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 20),
                                child: Row(
                                  children: [
                                    // Icon with pulse ring + float
                                    SizedBox(
                                      width: 60, height: 60,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Opacity(
                                            opacity: _pulseOpacity.value,
                                            child: Transform.scale(
                                              scale: _pulseScale.value,
                                              child: Container(
                                                width: 60, height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  color: Colors.white.withValues(alpha: 0.18),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Transform.translate(
                                            offset: Offset(0, _floatY.value),
                                            child: Container(
                                              width: 48, height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.22),
                                                ),
                                              ),
                                              child: Icon(
                                                widget.icon,
                                                color: Colors.white, size: 26,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 14),

                                    // Text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            widget.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: -0.2,
                                              height: 1.15,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            widget.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(alpha: 0.80),
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Chevron or loading spinner
                                    Transform.translate(
                                      offset: Offset(widget.isLoading ? 0 : _nudgeX.value, 0),
                                      child: Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.12),
                                        ),
                                        child: widget.isLoading
                                            ? Padding(
                                                padding: const EdgeInsets.all(7),
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white.withValues(alpha: 0.80),
                                                ),
                                              )
                                            : Icon(
                                                Icons.chevron_right_rounded,
                                                color: Colors.white.withValues(alpha: 0.70),
                                                size: 18,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final Color baseColor;
  final List<List<double>> particles;

  const _ParticlePainter({
    required this.t,
    required this.baseColor,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final angle = (t * 2 * math.pi + p[3]) % (2 * math.pi);
      final yOffset = math.sin(angle) * 6;
      final opacity = (math.sin(angle) * 0.17 + 0.25).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(size.width * p[0], size.height * p[1] + yOffset),
        p[2],
        Paint()
          ..color = baseColor.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
