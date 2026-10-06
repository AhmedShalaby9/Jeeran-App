import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../onboarding/presentation/pages/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController; // logo bloom + fades
  late final AnimationController _ringController; // expanding gold rings
  late final AnimationController _floatController; // gentle logo float
  late final AnimationController _sweepController; // progress sweep
  late final AnimationController _fadeController; // exit fade

  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;
  late final Animation<double> _barFade;
  late final Animation<double> _screenFadeAnimation;

  Future<void>? _profileRefresh;
  Future<void>? _settingsFetch;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Intro timeline (1700ms): logo 0–1000, tagline 500–1500, bar 900–1700.
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.59, curve: Cubic(.2, .8, .25, 1)),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.29, 0.88, curve: Curves.ease),
    );
    _barFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.53, 1.0, curve: Curves.ease),
    );
    _screenFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    // Both requests fire concurrently so latency is hidden in the animation.
    if (AppStorage.isLoggedIn) {
      _profileRefresh = _refreshProfile();
    }
    _settingsFetch = AppSettingsService.instance.fetch(sl<ApiClient>());

    _introController.forward();
    await Future.delayed(const Duration(milliseconds: 2400));
    _navigateToNextScreen();
  }

  Future<void> _refreshProfile() async {
    try {
      await sl<AuthRepository>().getMe().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  void _navigateToNextScreen() async {
    try {
      // Wait for both background requests concurrently, capped at 3 seconds total.
      final futures = <Future>[
        if (_profileRefresh != null) _profileRefresh!,
        if (_settingsFetch != null) _settingsFetch!,
      ];
      if (futures.isNotEmpty) {
        await Future.wait(
          futures,
        ).timeout(const Duration(seconds: 3), onTimeout: () => []);
      }

      if (!mounted) return;

      // --- Force-update check ---
      final settings = AppSettingsService.instance.settings;
      if (settings != null) {
        final minVersion = Platform.isIOS
            ? settings.minVersionIos
            : settings.minVersionAndroid;
        final storeUrl = Platform.isIOS
            ? settings.appStoreUrl
            : settings.googlePlayUrl;

        if (minVersion != null && minVersion.isNotEmpty) {
          final info = await PackageInfo.fromPlatform();
          final needsUpdate = AppUpdateService.isUpdateRequired(
            minVersion,
            info.version,
          );
          if (needsUpdate && mounted) {
            _showForceUpdateSheet(storeUrl);
            return;
          }
        }
      }
    } catch (_) {
      // Any unexpected error must not block navigation.
    }

    if (!mounted) return;
    await _fadeController.forward();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          if (!AppStorage.isLoggedIn && AppStorage.isFirstTimeUser) {
            return const OnboardingScreen();
          }
          if (!AppStorage.isLoggedIn) return const LoginPage();
          return const MainPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        transitionDuration: Duration.zero,
      ),
    );
  }

  void _showForceUpdateSheet(String? storeUrl) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ForceUpdateSheet(storeUrl: storeUrl),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _ringController.dispose();
    _floatController.dispose();
    _sweepController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  static const double _logoSize = 132;

  Widget _ring(double phase) {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (_, _) {
        final t = Curves.linear.transform((_ringController.value + phase) % 1);
        final eased = const Cubic(.2, .7, .3, 1).transform(t);
        return Opacity(
          opacity: 0.55 * (1 - t),
          child: Transform.scale(
            scale: 0.7 + 1.2 * eased,
            child: Container(
              width: _logoSize,
              height: _logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: JV2.goldEdge),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _progressBar() {
    return FadeTransition(
      opacity: _barFade,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: 2,
          child: LayoutBuilder(
            builder: (context, c) {
              final barW = c.maxWidth * 0.45;
              return Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: JV2.track)),
                  AnimatedBuilder(
                    animation: _sweepController,
                    builder: (_, _) {
                      // Sweeps across in the first 55% of the loop, then rests.
                      final p = (_sweepController.value / 0.55).clamp(0.0, 1.0);
                      final x =
                          (-1.4 + 5.0 * Curves.easeInOut.transform(p)) * barW;
                      return Transform.translate(
                        offset: Offset(x, 0),
                        child: Container(
                          width: barW,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0x00B8893D), JV2.goldHi],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) =>
            Opacity(opacity: _screenFadeAnimation.value, child: child),
        child: Scaffold(
          backgroundColor: JV2.bgDeep,
          body: JV2Ambient(
            intensity: 1.15,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          _ring(0),
                          _ring(0.5),
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _introController,
                                curve: const Interval(0.0, 0.59),
                              ),
                              child: AnimatedBuilder(
                                animation: _floatController,
                                builder: (_, child) => Transform.translate(
                                  offset: Offset(
                                    0,
                                    -5 *
                                        Curves.easeInOut.transform(
                                          _floatController.value,
                                        ),
                                  ),
                                  child: child,
                                ),
                                child: Image.asset(
                                  'assets/icon/icon.png',
                                  width: _logoSize,
                                  height: _logoSize,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.home_rounded,
                                    size: 80,
                                    color: JV2.navy,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Text(
                          'onboarding.tagline'.tr().toUpperCase(),
                          style: JV2.eyebrow,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(72, 0, 72, bottom + 66),
                  child: _progressBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Force-update bottom sheet ─────────────────────────────────────────────────

class _ForceUpdateSheet extends StatelessWidget {
  final String? storeUrl;
  const _ForceUpdateSheet({this.storeUrl});

  Future<void> _openStore() async {
    final url = storeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle (visual only — drag disabled)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // App icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/icon/icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.primary,
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Update Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'A new version of Jeeran is available. Please update to continue using the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.inkSub,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: storeUrl?.isNotEmpty == true ? _openStore : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.grey.withValues(
                    alpha: 0.3,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Update Now',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
