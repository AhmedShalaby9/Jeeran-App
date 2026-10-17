import 'dart:async';
import 'dart:math' as math;

import 'package:app_settings/app_settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/jv2.dart';
import '../ai_chat/ask/ask_api.dart';
import '../ai_chat/ask/ask_view.dart';
import '../ai_chat/ask/ask_widgets.dart';
import '../compounds/presentation/pages/compound_page.dart';
import '../explore/presentation/widgets/explore_widgets.dart' show chevronIcon;
import '../properties/data/models/property_model.dart';
import '../properties/presentation/pages/property_details_page.dart';
import '../listing/listing_checklist.dart';
import 'voice_api.dart';
import 'voice_services.dart';

const double _pad = 22;
const int _maxSeconds = 120;

enum _Phase {
  idle,
  recording,
  transcribing,
  thinking,
  answer,
  nospeech,
  denied,
  failed,
}

/// Ask out loud: record → transcribe → search → the answer is written and read back, all on this screen.
/// What was heard is always shown and always editable (Egyptian Arabic mixed with English place names is
/// misheard often enough that hiding it would make the screen unusable). "Continue in Ask" carries the
/// conversation on in the chat.
class VoicePage extends StatefulWidget {
  final VoiceApi? api; // tests inject fakes
  final VoiceRecorder? recorder;
  final AskApi? askApi;
  const VoicePage({super.key, this.api, this.recorder, this.askApi});

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage>
    with SingleTickerProviderStateMixin {
  late final VoiceApi _api = widget.api ?? VoiceApi(sl<ApiClient>());
  late final VoiceRecorder _rec = widget.recorder ?? DeviceRecorder();
  late final AskApi _ask = widget.askApi ?? AskApi(sl<ApiClient>());
  final _text = TextEditingController();
  final _scroll = ScrollController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );

  _Phase _phase = _Phase.idle;
  String _langChoice =
      'auto'; // auto | ar | en — what the recording is transcribed as
  int _seconds = 0;
  int? _sessionId;
  String _title = '';
  String _heard = '';
  bool _editing = false;
  Timer? _tick;

  // the answer
  AskReply? _reply;
  int _revealed = 0;
  Timer? _typer;

  @override
  void dispose() {
    _tick?.cancel();
    _typer?.cancel();
    if (widget.recorder == null) _rec.dispose();
    _text.dispose();
    _scroll.dispose();
    _anim.dispose();
    super.dispose();
  }

  String get _lang => context.locale.languageCode;

  void _setPhase(_Phase p) {
    if (!mounted) return;
    setState(() => _phase = p);
    // the halo rings only run while recording
    if (p == _Phase.recording) {
      _anim.repeat();
    } else {
      _anim.stop();
    }
  }

  // ── recording ────────────────────────────────────────────

  Future<void> _start() async {
    _typer?.cancel();
    if (!await _rec.requestPermission()) {
      _setPhase(_Phase.denied);
      return;
    }
    try {
      await _rec.start();
    } catch (_) {
      _setPhase(_Phase.failed);
      return;
    }
    if (!mounted) return;
    setState(() {
      _seconds = 0;
      _editing = false;
    });
    _setPhase(_Phase.recording);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= _maxSeconds) _stop();
    });
  }

  Future<void> _stop() async {
    _tick?.cancel();
    final seconds = _seconds;
    _setPhase(_Phase.transcribing);
    try {
      final path = await _rec.stop();
      if (path == null || seconds < 1) {
        _setPhase(_Phase.nospeech);
        return;
      }
      final heard = await _api.transcribe(
        path,
        seconds: seconds,
        language: _langChoice == 'auto' ? null : _langChoice,
      );
      if (!mounted) return;
      if (heard.transcript.isEmpty) {
        _setPhase(_Phase.nospeech);
        return;
      }
      _heard = heard.transcript;
      await _search(_heard, voiceId: heard.id);
    } catch (_) {
      _setPhase(_Phase.failed);
    }
  }

  // ── search + answer ──────────────────────────────────────

  Future<void> _search(String question, {int? voiceId}) async {
    final q = question.trim();
    if (q.isEmpty) return;
    setState(() {
      _heard = q;
      _editing = false;
      _reply = null;
      _revealed = 0;
    });
    _setPhase(_Phase.thinking);
    try {
      if (_sessionId == null) {
        _title = q.length > 60 ? '${q.substring(0, 60)}…' : q;
        _sessionId = await _ask.createSession(_title, _lang);
      }
      final reply = await _ask.send(_sessionId!, q, _lang, voiceId: voiceId);
      if (!mounted) return;
      setState(() => _reply = reply);
      _setPhase(_Phase.answer);
      _startTyping(_plain(reply.text).length);
    } catch (_) {
      _setPhase(_Phase.failed);
    }
  }

  void _startTyping(int length) {
    _typer?.cancel();
    _typer = Timer.periodic(const Duration(milliseconds: 24), (t) {
      if (!mounted) return t.cancel();
      setState(() => _revealed = math.min(length, _revealed + 4));
      if (_revealed >= length) t.cancel();
    });
  }

  /// The answer without markdown marks, as it is read and shown here.
  static String _plain(String text) => text
      .replaceAll(RegExp(r'[*_#`>]'), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  /// The first paragraph is the spoken answer; anything after it is the follow-up question.
  static (String, String) _split(String text) {
    final i = text.indexOf('\n\n');
    return i > 0
        ? (text.substring(0, i).trim(), text.substring(i + 2).trim())
        : (text.trim(), '');
  }

  // ── exits ────────────────────────────────────────────────

  void _continueInAsk() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => AskView(
        embedded: false,
        api: widget.askApi,
        sessionId: _sessionId,
        sessionTitle: _title,
      ),
    ),
  );

  void _typeInstead() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => AskView(embedded: false, api: widget.askApi),
    ),
  );

  void _openProperty(Map<String, dynamic> raw) {
    // references carry numbers; the property model reads strings
    final fixed = {
      ...raw,
      'price': raw['price']?.toString(),
      'size': raw['size']?.toString(),
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PropertyDetailsPage(property: PropertyModel.fromJson(fixed)),
      ),
    );
  }

  void _cycleLanguage() {
    setState(() {
      _langChoice = switch (_langChoice) {
        'auto' => 'ar',
        'ar' => 'en',
        _ => 'auto',
      };
    });
  }

  // ── build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Stack(
        children: [
          // a soft glow behind the header; warmer-blue while listening
          Positioned(
            top: -150,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        JV2.navyGlow.withValues(
                          alpha: _phase == _Phase.recording ? 0.14 : 0.08,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.68],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(_pad, top + 8, _pad, 12),
                child: Row(
                  children: [
                    _RoundButton(
                      key: const Key('voice-close'),
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
                    _LangChip(
                      key: const Key('voice-lang'),
                      label: switch (_langChoice) {
                        'ar' => 'voice.lang_ar'.tr(),
                        'en' => 'voice.lang_en'.tr(),
                        _ => 'voice.lang_auto'.tr(),
                      },
                      // changing it mid-recording would not change what is already being captured
                      onTap: _phase == _Phase.recording ? null : _cycleLanguage,
                    ),
                  ],
                ),
              ),
              Expanded(child: _body()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.nospeech:
      case _Phase.denied:
      case _Phase.failed:
        return Padding(
          padding: const EdgeInsets.fromLTRB(_pad, 0, _pad, 26),
          child: _notice(),
        );
      case _Phase.answer:
        return _answer();
      default:
        return Padding(
          padding: const EdgeInsets.fromLTRB(_pad, 0, _pad, 26),
          child: _capture(),
        );
    }
  }

  // idle · recording · transcribing · thinking
  Widget _capture() {
    final recording = _phase == _Phase.recording;
    final busy = _phase == _Phase.transcribing || _phase == _Phase.thinking;
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
        ] else ...[
          _Waveform(live: recording, flat: busy),
          const SizedBox(height: 22),
          if (recording)
            _TranscriptCard(key: const Key('voice-live'), live: true, text: '')
          else
            _TranscriptCard(
              live: _phase == _Phase.transcribing,
              text: _phase == _Phase.thinking ? _heard : '',
              partial: _phase == _Phase.transcribing,
            ),
          if (busy) ...[
            const SizedBox(height: 14),
            _BusyLine(
              label:
                  (_phase == _Phase.transcribing
                          ? 'voice.transcribing'
                          : 'voice.searching')
                      .tr(),
            ),
          ],
        ],
        const SizedBox(height: 28),
        _MicButton(
          mode: recording
              ? _MicMode.listening
              : busy
              ? _MicMode.busy
              : _MicMode.idle,
          anim: _anim,
          onTap: busy ? null : (recording ? _stop : _start),
        ),
        const SizedBox(height: 12),
        recording
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: JV2.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'voice.recording'.tr(
                      args: [
                        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: JV2.ink,
                    ),
                  ),
                ],
              )
            : Text(
                busy ? 'voice.working'.tr() : 'voice.tap'.tr(),
                style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
              ),
      ],
    );
  }

  // the written + spoken answer, with what it was built on
  Widget _answer() {
    final reply = _reply!;
    final full = _plain(reply.text);
    final (lead, tail) = _split(full);
    final shown = full.substring(0, math.min(full.length, _revealed));
    final typed = _revealed >= full.length;
    final leadShown = shown.length <= lead.length
        ? shown
        : lead; // the follow-up appears after the lead is complete
    final tailShown = shown.length > lead.length
        ? shown.substring(math.min(shown.length, lead.length)).trim()
        : '';
    final refs = reply.refs;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(_pad, 6, _pad, 20),
            children: [
              _TranscriptCard(
                text: _heard,
                editing: _editing,
                controller: _text,
                onEdit: () => setState(() {
                  _text.text = _heard;
                  _editing = true;
                }),
                onRedo: _start,
                onCancelEdit: () => setState(() => _editing = false),
                onSend: () => _search(_text.text),
              ),
              const SizedBox(height: 16),
              _SpokenReply(
                lead: leadShown,
                tail: typed ? tail : tailShown,
                typing: !typed,
                progress: full.isEmpty ? 1 : _revealed / full.length,
              ),
              if (typed && refs.listing != null) ...[
                const SizedBox(height: 16),
                ListingChecklistCard(reply: refs.listing!, said: _heard),
              ],
              if (typed && refs.properties.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionLabel('voice.behind'.tr()),
                const SizedBox(height: 9),
                AskPropertyRail(items: refs.properties, onTap: _openProperty),
              ],
              if (typed && refs.projects.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionLabel('voice.compounds'.tr()),
                const SizedBox(height: 9),
                AskCompoundChips(
                  items: refs.projects,
                  onTap: (id, name) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompoundPage(compoundId: id, name: name),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            _pad,
            12,
            _pad,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          decoration: const BoxDecoration(
            color: Color(0xF0FAFBFD),
            border: Border(top: BorderSide(color: JV2.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: const Key('voice-continue'),
                  onTap: _continueInAsk,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: JV2.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: JV2.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'voice.continue_ask'.tr(),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: JV2.ink,
                            ),
                          ),
                        ),
                        Icon(chevronIcon(context), size: 18, color: JV2.inkSub),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                key: const Key('voice-mic'),
                onTap: _start,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [JV2.navyLift, JV2.navy],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3D0B2A4A),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                key: const Key('voice-notice-primary'),
                label:
                    (k == 'denied' ? 'voice.open_settings' : 'voice.try_again')
                        .tr(),
                primary: true,
                onTap: () {
                  if (k == 'denied') {
                    AppSettings.openAppSettings().catchError((_) {});
                  }
                  _setPhase(_Phase.idle);
                },
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _Pill(
                key: const Key('voice-type-instead'),
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

// ── pieces ───────────────────────────────────────────────

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({super.key, required this.icon, required this.onTap});

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

class _LangChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _LangChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: JV2.fillFaint,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: JV2.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 14, color: JV2.inkSub),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: JV2.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _Pill({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: JV2.goldHi,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: JV2.inkSub,
          ),
        ),
      ),
    ],
  );
}

enum _MicMode { idle, listening, busy }

/// The record control: navy when idle, gold with expanding rings while listening, grey spinner while working.
class _MicButton extends StatelessWidget {
  final _MicMode mode;
  final Animation<double> anim;
  final VoidCallback? onTap;
  const _MicButton({required this.mode, required this.anim, this.onTap});

  @override
  Widget build(BuildContext context) {
    final listening = mode == _MicMode.listening;
    final busy = mode == _MicMode.busy;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (listening)
            AnimatedBuilder(
              animation: anim,
              builder: (_, _) => Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    () {
                      final t = (anim.value + i * 0.33) % 1.0;
                      return Opacity(
                        opacity: (0.5 * (1 - t)).clamp(0, 0.5),
                        child: Transform.scale(
                          scale: 0.85 + 0.7 * t,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: JV2.goldHi, width: 2),
                            ),
                          ),
                        ),
                      );
                    }(),
                ],
              ),
            ),
          GestureDetector(
            key: const Key('voice-mic'),
            onTap: onTap,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: busy
                      ? const [JV2.fillHi, JV2.fillHi]
                      : listening
                      ? const [JV2.goldHi, JV2.gold]
                      : const [JV2.navyLift, JV2.navy],
                ),
                boxShadow: busy
                    ? null
                    : [
                        BoxShadow(
                          color: listening
                              ? const Color(0x6BB8893D)
                              : const Color(0x4D0B2A4A),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
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
                    : listening
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
        ],
      ),
    );
  }
}

/// "Working…" with three pulsing gold dots.
class _BusyLine extends StatefulWidget {
  final String label;
  const _BusyLine({required this.label});

  @override
  State<_BusyLine> createState() => _BusyLineState();
}

class _BusyLineState extends State<_BusyLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        widget.label,
        style: const TextStyle(fontSize: 13, color: JV2.inkSub),
      ),
      const SizedBox(width: 9),
      AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: JV2.goldHi.withValues(
                    alpha:
                        0.25 +
                        0.75 *
                            (0.5 +
                                    0.5 *
                                        math.sin(
                                          (_c.value - i * 0.16) * 2 * math.pi,
                                        ))
                                .abs(),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// What was heard. Live (gold edge) while recording / transcribing; final with Edit and Re-record once known.
class _TranscriptCard extends StatelessWidget {
  final String text;
  final bool live;
  final bool partial;
  final bool editing;
  final TextEditingController? controller;
  final VoidCallback? onEdit, onRedo, onCancelEdit, onSend;
  const _TranscriptCard({
    super.key,
    required this.text,
    this.live = false,
    this.partial = false,
    this.editing = false,
    this.controller,
    this.onEdit,
    this.onRedo,
    this.onCancelEdit,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final final_ = !live && onEdit != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: live ? JV2.goldEdge : JV2.line),
        boxShadow: live
            ? const [BoxShadow(color: Color(0x1AB8893D), spreadRadius: 3)]
            : const [
                BoxShadow(
                  color: Color(0x0F0B2A4A),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: live ? JV2.goldHi : JV2.success,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                (live ? 'voice.hearing' : 'voice.transcribed')
                    .tr()
                    .toUpperCase(),
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
          if (editing)
            TextField(
              key: const Key('voice-text'),
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                color: JV2.ink,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            )
          else
            Text(
              text.isEmpty ? 'voice.listening'.tr() : text,
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: text.isEmpty ? JV2.inkMute : JV2.ink,
              ),
            ),
          if (final_) ...[
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _MiniButton(
                    key: Key(editing ? 'voice-cancel-edit' : 'voice-edit'),
                    label: (editing ? 'voice.cancel' : 'voice.edit_text').tr(),
                    onTap: editing ? onCancelEdit : onEdit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniButton(
                    key: Key(editing ? 'voice-send' : 'voice-redo'),
                    label: (editing ? 'voice.send' : 'voice.rerecord').tr(),
                    onTap: editing ? onSend : onRedo,
                    primary: editing,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  const _MiniButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? JV2.navy : JV2.fillFaint,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: primary ? JV2.navy : JV2.line),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: primary ? Colors.white : JV2.ink,
        ),
      ),
    ),
  );
}

/// The answer on a navy card: a progress bar while it types out, then the text.
class _SpokenReply extends StatelessWidget {
  final String lead, tail;
  final bool typing;
  final double progress;
  const _SpokenReply({
    required this.lead,
    required this.tail,
    required this.typing,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('voice-reply'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [JV2.navyLift, JV2.navy],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x380B2A4A),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0x24FFFFFF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'voice.voice_reply'.tr(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xC7FFFFFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 3,
              backgroundColor: const Color(0x2EFFFFFF),
              valueColor: const AlwaysStoppedAnimation(JV2.goldHi),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            typing ? '$lead▍' : lead,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.55,
              color: Colors.white,
            ),
          ),
          if (tail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              tail,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: Color(0xCCFFFFFF),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Waveform extends StatefulWidget {
  final bool live;
  final bool flat;
  final Color? color;
  final double height;
  final int bars;
  const _Waveform({
    required this.live,
    this.flat = false,
    this.color,
    this.height = 58,
    this.bars = 30,
  });

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.live) _c.repeat();
  }

  @override
  void didUpdateWidget(_Waveform old) {
    super.didUpdateWidget(old);
    if (widget.live && !_c.isAnimating) _c.repeat();
    if (!widget.live) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? (widget.live ? JV2.navy : JV2.inkMute);
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.bars; i++)
              Container(
                width: 3.5,
                height: widget.live
                    ? 8 +
                          (widget.height - 8) *
                              (0.5 +
                                      0.5 *
                                          math.sin(
                                            _c.value * 2 * math.pi + i * 0.7,
                                          ))
                                  .abs()
                    : (widget.flat ? 10 : widget.height * 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 1.75),
                decoration: BoxDecoration(
                  color: widget.flat ? color.withValues(alpha: 0.3) : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
