import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/jv2.dart';

const _sand = Color(
  0xFFE5C48F,
); // the light gold of the design's mic and labels

/// Jeeran's front door on Explore (design "AI bar"): one navy card. Tap the text to type to Ask,
/// tap the gold mic to talk. Replaces the search field and the mic button.
class AskEntry extends StatelessWidget {
  final VoidCallback onAsk;
  final VoidCallback? onVoice; // null hides the mic

  const AskEntry({super.key, required this.onAsk, this.onVoice});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        key: const Key('ask-entry'),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment(-0.6, -1),
            end: Alignment(0.6, 1),
            colors: [JV2.navyLift, JV2.navy],
            stops: [0, 0.75],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x420B2A4A),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(child: _Sheen()),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    key: const Key('ask-entry-text'),
                    onTap: onAsk,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0x29E5C48F),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: _sand,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'explore.ask_jeeran'.tr().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: _sand,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const RotatingPrompt(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (onVoice != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Tooltip(
                      message: 'explore.voice_tooltip'.tr(),
                      child: GoldMic(
                        key: const Key('explore-mic'),
                        size: 52,
                        onTap: onVoice!,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A faint gold glint that crosses the card now and then.
class _Sheen extends StatefulWidget {
  const _Sheen();

  @override
  State<_Sheen> createState() => _SheenState();
}

class _SheenState extends State<_Sheen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
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
            final t = (_c.value / 0.6).clamp(0.0, 1.0);
            return Stack(
              children: [
                Positioned(
                  left: -60 + t * (c.maxWidth + 120),
                  top: 0,
                  bottom: 0,
                  width: 60,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00E5C48F),
                          Color(0x38E5C48F),
                          Color(0x00E5C48F),
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

const _prompts = ['voice.ex1', 'voice.ex2', 'voice.ex3'];

/// Example questions, one at a time: each slides up and fades in, rests, then lifts away.
class RotatingPrompt extends StatefulWidget {
  const RotatingPrompt({super.key});

  @override
  State<RotatingPrompt> createState() => _RotatingPromptState();
}

class _RotatingPromptState extends State<RotatingPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _i = (_i + 1) % _prompts.length);
        _c.forward(from: 0);
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          // in during the first 12%, out during the last 12%
          final opacity = t < 0.12
              ? t / 0.12
              : (t > 0.88 ? (1 - t) / 0.12 : 1.0);
          final dy = t < 0.12
              ? 8 * (1 - t / 0.12)
              : (t > 0.88 ? -8 * ((t - 0.88) / 0.12) : 0.0);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, dy), child: child),
          );
        },
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '“${_prompts[_i].tr()}”',
            key: Key('ask-prompt-$_i'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xEBFFFFFF),
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

/// The gold microphone: a gradient disc with a glint, a breathing glow and two rings spreading out.
class GoldMic extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  const GoldMic({super.key, this.size = 52, required this.onTap});

  @override
  State<GoldMic> createState() => _GoldMicState();
}

class _GoldMicState extends State<GoldMic> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      button: true,
      label: 'explore.voice_tooltip'.tr(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (final delay in const [0.0, 0.5])
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) {
                    final t = (_pulse.value + delay) % 1;
                    return Opacity(
                      opacity: 0.55 * (1 - t),
                      child: Transform.scale(
                        scale: 0.9 + 0.8 * t,
                        child: Container(
                          width: s,
                          height: s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xBFE5C48F),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final k = math.sin(
                    _pulse.value * math.pi,
                  ); // 0 → 1 → 0 over the cycle
                  return Container(
                    width: s,
                    height: s,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment(-0.3, -1),
                        end: Alignment(0.3, 1),
                        colors: [_sand, JV2.goldHi],
                        stops: [0, 0.7],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(184, 137, 61, 0.38 + 0.12 * k),
                          blurRadius: 26 + 4 * k,
                          offset: Offset(0, 10 + 2 * k),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _shine,
                      builder: (_, _) {
                        final t = (_shine.value / 0.6).clamp(0.0, 1.0);
                        return Positioned(
                          left: -s * 0.35 + t * s * 1.7,
                          top: 0,
                          bottom: 0,
                          width: s * 0.35,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x00FFFFFF),
                                  Color(0x8CFFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Icon(
                      Icons.mic_none_rounded,
                      size: s * 0.46,
                      color: JV2.navy,
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
