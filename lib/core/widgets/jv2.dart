import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jeeran v2 design tokens (light). Ported from the design project's
/// `tokens-v2.jsx` — brand navy + tan on a warm-white canvas.
class JV2 {
  JV2._();

  // canvas
  static const Color bgDeep = Color(0xFFFAFBFD);
  static const Color surface = Colors.white;

  // brand navy — primary action
  static const Color navy = Color(0xFF0B2A4A);
  static const Color navyLift = Color(0xFF12395F);
  static const Color navyGlow = Color(0xFF1A4A80);

  // brand tan — accent. `gold` is the text-safe darker tan.
  static const Color gold = Color(0xFF8A5F12);
  static const Color goldHi = Color(0xFFB8893D);
  static const Color goldEdge = Color(0x6BB8893D); // .42

  // ink
  static const Color ink = Color(0xFF0E1726);
  static const Color inkSub = Color(0xFF5B6474);
  static const Color inkMute = Color(0xFF8A93A3);

  // lines + fills
  static const Color line = Color(0x1A0B2A4A); // .10
  static const Color goldFilm = Color(0x1AB8893D); // .10
  static const Color fillFaint = Color(0x090B2A4A); // .035
  static const Color fillHi = Color(0x120B2A4A); // .07
  static const Color track = Color(0x1A0B2A4A); // .10

  static const Color success = Color(0xFF137A55);
  static const Color danger = Color(0xFFC23B3B);
  static const Color warnText = Color(0xFF8A5F12);

  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x120B2A4A), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Serif display face — Instrument Serif for Latin, Cairo for Arabic.
  static TextStyle display(BuildContext context, double size) {
    final isArabic = context.locale.languageCode == 'ar';
    final base = isArabic
        ? GoogleFonts.cairo(fontWeight: FontWeight.w700)
        : GoogleFonts.instrumentSerif();
    return base.copyWith(
      fontSize: size,
      height: isArabic ? 1.3 : 1.08,
      color: ink,
      letterSpacing: isArabic ? 0 : -0.4,
    );
  }

  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: gold,
  );

  static const TextStyle sub = TextStyle(
    fontSize: 14.5,
    height: 1.5,
    color: inkSub,
  );
}

/// Soft navy + tan light wash behind a screen.
class JV2Ambient extends StatefulWidget {
  final double intensity;
  final Widget child;

  const JV2Ambient({super.key, this.intensity = 1, required this.child});

  @override
  State<JV2Ambient> createState() => _JV2AmbientState();
}

class _JV2AmbientState extends State<JV2Ambient> with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);
  late final AnimationController _b = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  Widget _orb({
    required Animation<double> anim,
    required Color color,
    required double size,
    required Offset drift,
  }) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(anim.value);
        return Transform.translate(
          offset: drift * t,
          child: Transform.scale(
            scale: 1 + 0.16 * t,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color, color.withValues(alpha: 0)],
                  stops: const [0, 0.68],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.intensity;
    return ColoredBox(
      color: JV2.bgDeep,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -170,
            left: -90,
            child: IgnorePointer(
              child: _orb(
                anim: _a,
                color: JV2.navyGlow.withValues(alpha: 0.13 * k),
                size: 430,
                drift: const Offset(-18, 14),
              ),
            ),
          ),
          Positioned(
            bottom: -190,
            right: -130,
            child: IgnorePointer(
              child: _orb(
                anim: _b,
                color: JV2.goldHi.withValues(alpha: 0.15 * k),
                size: 410,
                drift: const Offset(18, -14),
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

/// Navy primary action with a soft lift shadow.
class JV2PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;

  const JV2PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: disabled
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [JV2.navyLift, JV2.navy],
                ),
          color: disabled ? JV2.fillHi : null,
          boxShadow: disabled
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x380B2A4A), // .22
                    blurRadius: 26,
                    offset: Offset(0, 10),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onPressed,
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: disabled ? JV2.inkMute : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: disabled ? JV2.inkMute : Colors.white,
                    size: 18,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The glyph of the logo, cropped out of the square icon asset (which also
/// holds the bilingual wordmark). Mark bbox in the 1024px source:
/// x 240–700, y 145–680.
class JV2Mark extends StatelessWidget {
  final double size;
  final double opacity;

  const JV2Mark({super.key, this.size = 56, this.opacity = 1});

  static const double _l = 240 / 1024, _t = 145 / 1024;
  static const double _w = 460 / 1024, _h = 535 / 1024;

  @override
  Widget build(BuildContext context) {
    final full = size / _h; // scale so mark height == size
    final cropW = full * _w;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: cropW,
        height: size,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: full,
            maxWidth: full,
            minHeight: full,
            maxHeight: full,
            child: Transform.translate(
              offset: Offset(-_l * full, -_t * full),
              child: Image.asset(
                'assets/icon/icon.png',
                width: full,
                height: full,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.home_rounded, color: JV2.navy),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action: white surface, hairline border.
class JV2GhostButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const JV2GhostButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: JV2.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: JV2.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                color: JV2.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Square back button used at the top-left of sub-screens.
class JV2BackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const JV2BackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    return Material(
      color: const Color(0x090B2A4A), // .035
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: JV2.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed ?? () => Navigator.maybePop(context),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            isRtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            size: 22,
            color: JV2.ink,
          ),
        ),
      ),
    );
  }
}

/// Segmented progress bar — filled segments are tan.
class JV2StepBar extends StatelessWidget {
  final int step;
  final int total;

  const JV2StepBar({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsetsDirectional.only(end: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: JV2.track,
              borderRadius: BorderRadius.circular(2),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: i < step ? 1 : 0),
              duration: const Duration(milliseconds: 500),
              curve: const Cubic(.2, .8, .3, 1),
              builder: (_, v, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [JV2.goldHi, JV2.gold],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Labelled text field with the v2 focus treatment (tan edge + halo).
/// Pass [onTap] and [readOnly] to use it as a picker row instead.
class JV2Field extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final String? placeholder;
  final String? text; // display text when there is no controller (pickers)
  final Widget? prefix;
  final Widget? suffix;
  final String? hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  const JV2Field({
    super.key,
    this.label,
    this.controller,
    this.placeholder,
    this.text,
    this.prefix,
    this.suffix,
    this.hint,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });

  @override
  State<JV2Field> createState() => _JV2FieldState();
}

class _JV2FieldState extends State<JV2Field> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final isPicker = widget.controller == null;
    final empty = (widget.text ?? '').isEmpty;
    final readOnlyFill = widget.readOnly;

    final box = Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: readOnlyFill ? const Color(0x090B2A4A) : JV2.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: focused ? JV2.goldEdge : JV2.line),
        boxShadow: focused
            ? const [BoxShadow(color: Color(0x21B8893D), spreadRadius: 3)]
            : (readOnlyFill
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0D0B2A4A),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ]),
      ),
      child: Row(
        children: [
          if (widget.prefix != null) ...[
            widget.prefix!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: isPicker
                ? Text(
                    empty ? (widget.placeholder ?? '') : widget.text!,
                    style: TextStyle(
                      fontSize: 16,
                      color: empty
                          ? JV2.inkMute
                          : (widget.readOnly ? JV2.inkSub : JV2.ink),
                    ),
                  )
                : TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    readOnly: widget.readOnly,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                    textCapitalization: widget.textCapitalization,
                    textInputAction: widget.textInputAction,
                    cursorColor: JV2.goldHi,
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.readOnly ? JV2.inkSub : JV2.ink,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.placeholder,
                      hintStyle: const TextStyle(
                        color: JV2.inkMute,
                        fontSize: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                  ),
          ),
          if (widget.suffix != null) ...[
            const SizedBox(width: 10),
            widget.suffix!,
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: focused ? JV2.gold : JV2.inkMute,
            ),
          ),
          const SizedBox(height: 8),
        ],
        widget.onTap != null
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: box,
              )
            : box,
        if (widget.hint != null) ...[
          const SizedBox(height: 7),
          Text(
            widget.hint!,
            style: const TextStyle(
              fontSize: 12,
              color: JV2.inkMute,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// A soft gold glint that crosses its parent every few seconds (the Ask buttons). Put it inside a
/// clipped container; it ignores touches. [period] is the whole cycle — the glint itself is the first part of it.
class JV2GoldSweep extends StatefulWidget {
  final double width;
  final Duration period;
  const JV2GoldSweep({
    super.key,
    this.width = 22,
    this.period = const Duration(milliseconds: 5500),
  });

  @override
  State<JV2GoldSweep> createState() => _JV2GoldSweepState();
}

class _JV2GoldSweepState extends State<JV2GoldSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, c) => AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            // the glint crosses during the first 30% of the cycle, then rests
            final t = (_c.value / 0.3).clamp(0.0, 1.0);
            final x = -widget.width + t * (c.maxWidth + widget.width);
            return Stack(
              children: [
                Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  width: widget.width,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00B8893D),
                          Color(0x99B8893D),
                          Color(0x00B8893D),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
