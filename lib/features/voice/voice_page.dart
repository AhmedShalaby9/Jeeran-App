import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/jv2.dart';
import '../ai_chat/ask/ask_api.dart';
import '../ai_chat/ask/ask_view.dart';
import 'voice_api.dart';
import 'voice_services.dart';

const double _pad = 22;
const int _maxSeconds = 120;

enum _Phase { idle, recording, transcribing, review, nospeech, denied, failed }

/// Ask out loud: record, see (and fix) what was heard, then the answer is read back in Ask.
/// The audio is kept on the server for the team; the transcript is always shown and editable.
class VoicePage extends StatefulWidget {
  final VoiceApi? api; // tests inject fakes
  final VoiceRecorder? recorder;
  final VoiceSpeaker? speaker;
  final AskApi? askApi;
  const VoicePage({
    super.key,
    this.api,
    this.recorder,
    this.speaker,
    this.askApi,
  });

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  late final VoiceApi _api = widget.api ?? VoiceApi(sl<ApiClient>());
  late final VoiceRecorder _rec = widget.recorder ?? DeviceRecorder();
  late final VoiceSpeaker _speaker = widget.speaker ?? DeviceSpeaker();
  final _text = TextEditingController();

  _Phase _phase = _Phase.idle;
  int _seconds = 0;
  int? _voiceId;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    if (widget.recorder == null) _rec.dispose();
    _text.dispose();
    super.dispose();
  }

  String get _lang => context.locale.languageCode;

  Future<void> _start() async {
    await _speaker.stop();
    if (!await _rec.requestPermission()) {
      if (mounted) setState(() => _phase = _Phase.denied);
      return;
    }
    try {
      await _rec.start();
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.failed);
      return;
    }
    if (!mounted) return;
    setState(() {
      _phase = _Phase.recording;
      _seconds = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= _maxSeconds) _stop();
    });
  }

  Future<void> _stop() async {
    _tick?.cancel();
    final seconds = _seconds;
    setState(() => _phase = _Phase.transcribing);
    try {
      final path = await _rec.stop();
      if (path == null || seconds < 1) {
        if (mounted) setState(() => _phase = _Phase.nospeech);
        return;
      }
      final heard = await _api.transcribe(
        path,
        seconds: seconds,
        language: _lang,
      );
      if (!mounted) return;
      if (heard.transcript.isEmpty) {
        setState(() => _phase = _Phase.nospeech);
        return;
      }
      _voiceId = heard.id;
      _text.text = heard.transcript;
      setState(() => _phase = _Phase.review);
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  void _ask() {
    final q = _text.text.trim();
    if (q.isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AskView(
          embedded: false,
          api: widget.askApi,
          initialQuestion: q,
          voiceId: _voiceId,
          speaker: _speaker,
        ),
      ),
    );
  }

  void _typeInstead() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const AskView(embedded: false)),
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(_pad, top + 8, _pad, 12),
            child: Row(
              children: [
                _RoundButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'voice.title'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 38),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_pad, 0, _pad, 26),
              child: _body(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_phase) {
      case _Phase.nospeech:
      case _Phase.denied:
      case _Phase.failed:
        return _notice();
      case _Phase.review:
        return _review();
      default:
        return _record();
    }
  }

  Widget _record() {
    final recording = _phase == _Phase.recording;
    final busy = _phase == _Phase.transcribing;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_phase == _Phase.idle) ...[
          Text(
            'voice.idle_title'.tr(),
            textAlign: TextAlign.center,
            style: JV2.display(context, 26),
          ),
          const SizedBox(height: 12),
          Text(
            'voice.idle_sub'.tr(),
            textAlign: TextAlign.center,
            style: JV2.sub,
          ),
          const SizedBox(height: 24),
          Text(
            'voice.examples'.tr().toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: JV2.inkSub,
            ),
          ),
          const SizedBox(height: 8),
          for (final k in const ['ex1', 'ex2', 'ex3'])
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: JV2.line),
              ),
              child: Text(
                '“${'voice.$k'.tr()}”',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: JV2.ink),
              ),
            ),
        ] else
          _Waveform(live: recording),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: busy ? null : (recording ? _stop : _start),
          child: Container(
            key: const Key('voice-mic'),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: busy
                    ? const [JV2.fillHi, JV2.fillHi]
                    : recording
                    ? const [JV2.goldHi, JV2.gold]
                    : const [JV2.navyLift, JV2.navy],
              ),
              boxShadow: busy
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x4D0B2A4A),
                        blurRadius: 30,
                        offset: Offset(0, 12),
                      ),
                    ],
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: JV2.gold,
                      ),
                    )
                  : recording
                  ? Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )
                  : const Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          busy
              ? 'voice.working'.tr()
              : recording
              ? 'voice.recording'.tr(
                  args: [
                    '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                  ],
                )
              : 'voice.tap'.tr(),
          style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
        ),
      ],
    );
  }

  Widget _review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: JV2.line),
            boxShadow: JV2.shadowMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: JV2.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'voice.heard'.tr().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: JV2.inkSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              TextField(
                key: const Key('voice-text'),
                controller: _text,
                minLines: 2,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: JV2.ink,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
              Text(
                'voice.edit_hint'.tr(),
                style: const TextStyle(fontSize: 11, color: JV2.inkMute),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Pill(
                label: 'voice.rerecord'.tr(),
                onTap: () => setState(() => _phase = _Phase.idle),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _Pill(label: 'voice.ask'.tr(), onTap: _ask, primary: true),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _notice() {
    final k = switch (_phase) {
      _Phase.denied => 'denied',
      _Phase.failed => 'failed',
      _ => 'nospeech',
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: JV2.fillHi,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: JV2.line),
          ),
          child: Icon(
            k == 'denied' ? Icons.lock_outline_rounded : Icons.mic_off_rounded,
            color: JV2.inkSub,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'voice.${k}_title'.tr(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: JV2.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'voice.${k}_sub'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.5, color: JV2.inkSub),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Pill(
                label: 'voice.try_again'.tr(),
                primary: true,
                onTap: () => setState(() => _phase = _Phase.idle),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _Pill(
                label: 'voice.type_instead'.tr(),
                onTap: _typeInstead,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: JV2.line),
      ),
      child: Icon(icon, size: 18, color: JV2.ink),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool wide;
  const _Pill({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.wide = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      padding: wide ? null : const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? null : JV2.surface,
        gradient: primary
            ? const LinearGradient(colors: [JV2.navyLift, JV2.navy])
            : null,
        borderRadius: BorderRadius.circular(14),
        border: primary ? null : Border.all(color: JV2.line),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primary ? Colors.white : JV2.ink,
        ),
      ),
    ),
  );
}

class _Waveform extends StatefulWidget {
  final bool live;
  const _Waveform({required this.live});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < 30; i++)
            Container(
              width: 3.5,
              height: widget.live
                  ? 8 +
                        50 *
                            (0.5 +
                                    0.5 *
                                        math.sin(
                                          _c.value * 2 * math.pi + i * 0.7,
                                        ))
                                .abs()
                  : 10,
              margin: const EdgeInsets.symmetric(horizontal: 1.75),
              decoration: BoxDecoration(
                color: widget.live ? JV2.navy : JV2.inkMute,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    ),
  );
}
