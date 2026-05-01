import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/image_paths.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../subscription/presentation/pages/subscription_details_page.dart';

class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthMeLoaded ? state.user : null;
        return _HomeSliverAppBarView(user: user);
      },
    );
  }
}

class _HomeSliverAppBarView extends StatefulWidget {
  final User? user;
  const _HomeSliverAppBarView({required this.user});

  @override
  State<_HomeSliverAppBarView> createState() => _HomeSliverAppBarViewState();
}

class _HomeSliverAppBarViewState extends State<_HomeSliverAppBarView> {
  final int _unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    final isSeller = widget.user?.isSeller ?? false;
    final hasSubscription = isSeller && (widget.user?.subscriptionId != null);
    final showSubscribeBtn = isSeller && !hasSubscription;
    final showPremiumBadge = isSeller && hasSubscription;

    return SliverAppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      surfaceTintColor: Colors.transparent,
      pinned: false,
      floating: false,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppImage.asset(ImagePaths.appIcon, width: 36, height: 36),
          const SizedBox(width: 8),
          const Text(
            'Jeeran',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        // ── Seller subscription badge ────────────────────────────
        if (showSubscribeBtn)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _SubscribeButton(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlansPage()),
              ),
            ),
          ),
        if (showPremiumBadge)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PremiumBadge(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionDetailsPage(),
                ),
              ),
            ),
          ),

        // ── Notifications bell ────────────────────────────────────
        GestureDetector(
          onTap: () {
            // TODO: navigate to notifications page
          },
          child: Container(
            margin: const EdgeInsets.only(left: 4, right: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.navButtonBg,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.onBackground,
                    size: 22,
                  ),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Subscribe button (seller, no plan) ──────────────────────────────
class _SubscribeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SubscribeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          'home.subscribe'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ── Premium badge (seller, has plan) — animated moving glow ─────────
class _PremiumBadge extends StatefulWidget {
  final VoidCallback onTap;
  const _PremiumBadge({required this.onTap});

  @override
  State<_PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<_PremiumBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Shadow orbit: one full rotation every 2 s
  static const _orbitDuration = Duration(milliseconds: 2000);
  // Horizontal orbit radius (pixels) — matches half the badge width
  static const double _orbitX = 36;
  // Vertical orbit radius — shallower so it feels like depth
  static const double _orbitY = 6;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _orbitDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          final angle = _ctrl.value * 2 * math.pi;
          final dx = math.cos(angle) * _orbitX;
          final dy = math.sin(angle) * _orbitY;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldLight, AppColors.gold],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                // Orbiting glow
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.75),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: Offset(dx, dy),
                ),
                // Static inner shadow for depth
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.30),
                  blurRadius: 6,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.workspace_premium_rounded,
              size: 15,
              color: AppColors.ink,
            ),
            SizedBox(width: 4),
            Text(
              'Premium',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
