import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/storage/app_storage.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../auth/presentation/pages/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const double _pad = 24;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_Slide> _slides = [
    _Slide(key: 's1', image: 'assets/onboarding/onb-compounds.png'),
    _Slide(key: 's2', image: 'assets/onboarding/onb-ask.png'),
    _Slide(key: 's3', image: 'assets/onboarding/onb-sell.png'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await AppStorage.setFirstTimeUser(false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLast = _currentPage == _slides.length - 1;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: JV2Ambient(
          intensity: 0.7,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _pad,
                  media.padding.top + 12,
                  _pad,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const JV2Mark(size: 30, opacity: 0.9),
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: JV2.inkSub,
                        padding: const EdgeInsets.all(6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'onboarding.skip'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) =>
                      _SlideView(slide: _slides[index], index: index),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _pad,
                  0,
                  _pad,
                  media.padding.bottom + 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(_slides.length, (i) {
                          final on = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsetsDirectional.only(end: 6),
                            width: on ? 26 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: on ? JV2.goldHi : JV2.track,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                    JV2PrimaryButton(
                      width: isLast ? 150 : 132,
                      height: 50,
                      onPressed: _nextPage,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLast
                                ? 'onboarding.get_started'.tr()
                                : 'onboarding.next'.tr(),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isRtl
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: 20,
                          ),
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
    );
  }
}

class _Slide {
  final String key; // translation prefix under `onboarding.`
  final String image;

  const _Slide({required this.key, required this.image});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final int index;

  const _SlideView({required this.slide, required this.index});

  @override
  Widget build(BuildContext context) {
    final k = 'onboarding.${slide.key}';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Scene(index: index, image: slide.image),
          const SizedBox(height: 24),
          Text('$k.eyebrow'.tr().toUpperCase(), style: JV2.eyebrow),
          const SizedBox(height: 12),
          Text('$k.title'.tr(), style: JV2.display(context, 36)),
          const SizedBox(height: 12),
          Text('$k.sub'.tr(), style: JV2.sub),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Scene — a photo with one piece of the real product over it
// ─────────────────────────────────────────────────────────

class _Scene extends StatelessWidget {
  final int index;
  final String image;

  const _Scene({required this.index, required this.image});

  static const _tints = [
    Color(0x3D1A4A80), // .24
    Color(0x47B8893D), // .28
    Color(0x4212395F),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: JV2.line),
        boxShadow: JV2.shadowMd,
        color: const Color(0xFFE8EDF3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            // Until the photo is dropped into assets/onboarding/, show a
            // tinted wash so the overlay stays legible.
            errorBuilder: (_, _, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFE8EDF3), _tints[index]],
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x470B2A4A),
                  Color(0x000B2A4A),
                  Color(0x570B2A4A),
                ],
                stops: [0, 0.34, 1],
              ),
            ),
          ),
          switch (index) {
            0 => const _CompoundOverlay(),
            1 => const _AskOverlay(),
            _ => const _SellOverlay(),
          },
        ],
      ),
    );
  }
}

/// Frosted white card used for every overlay.
class _Plate extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry radius;
  final EdgeInsetsGeometry padding;

  const _Plate({
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(15)),
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D0B2A4A), // .24
            blurRadius: 34,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xF0FFFFFF), // .94
              borderRadius: radius,
              border: Border.all(color: const Color(0xB3FFFFFF)), // .7
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CompoundOverlay extends StatelessWidget {
  const _CompoundOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: _Plate(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  begin: Alignment(-0.5, -1),
                  end: Alignment(0.5, 1),
                  colors: [Color(0xFFDCE5EF), Color(0xFFC9D6E4)],
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'onboarding.demo.compound'.tr(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: JV2.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 12,
                        color: JV2.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'onboarding.demo.developer'.tr(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: JV2.inkMute),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1F137A55), // .12
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'onboarding.demo.primary'.tr().toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: JV2.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskOverlay extends StatelessWidget {
  const _AskOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: c.maxWidth * 0.84),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-0.4, -1),
                        end: Alignment(0.4, 1),
                        colors: [JV2.navyLift, JV2.navy],
                      ),
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: Radius.circular(16),
                        topEnd: Radius.circular(16),
                        bottomStart: Radius.circular(16),
                        bottomEnd: Radius.circular(5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x520B2A4A), // .32
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      'onboarding.demo.ask_user'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: c.maxWidth * 0.88),
                  child: _Plate(
                    radius: const BorderRadiusDirectional.only(
                      topStart: Radius.circular(16),
                      topEnd: Radius.circular(16),
                      bottomStart: Radius.circular(5),
                      bottomEnd: Radius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: JV2.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'onboarding.demo.ai_label'.tr().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: JV2.gold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'onboarding.demo.ask_matches'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' ${'onboarding.demo.ask_rest'.tr()}',
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.42,
                            color: JV2.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellOverlay extends StatelessWidget {
  const _SellOverlay();

  @override
  Widget build(BuildContext context) {
    const stats = [('1,240', 'views'), ('38', 'saves'), ('6', 'calls')];
    return Stack(
      children: [
        Positioned(
          top: 14,
          right: 14,
          child: _Plate(
            radius: BorderRadius.circular(999),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: JV2.gold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'onboarding.demo.ad_ready'.tr(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: _Plate(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'onboarding.demo.villa'.tr(),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final (n, l) in stats) ...[
                      Text(
                        n,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: JV2.navy,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'onboarding.demo.$l'.tr(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: JV2.inkMute,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
