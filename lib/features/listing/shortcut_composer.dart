import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/jv2.dart';
import '../voice/voice_api.dart';
import '../voice/voice_services.dart';
import 'listing_widgets.dart';

/// The type-or-talk bar at the bottom of a shortcut: a text field, send, and a mic that records,
/// uploads (the team can listen later) and hands back what was heard as a normal message.
class ShortcutComposer extends StatefulWidget {
  final bool busy;
  final String hint;
  final void Function(String text, {bool voice}) onSend;

  /// Said back to the user in the thread (nothing heard, mic off …).
  final ValueChanged<String> onNotice;
  final VoiceRecorder? recorder;
  final VoiceApi? voiceApi;
  const ShortcutComposer({
    super.key,
    required this.busy,
    required this.hint,
    required this.onSend,
    required this.onNotice,
    this.recorder,
    this.voiceApi,
  });

  @override
  State<ShortcutComposer> createState() => _ShortcutComposerState();
}

class _ShortcutComposerState extends State<ShortcutComposer> {
  late final VoiceRecorder _rec = widget.recorder ?? DeviceRecorder();
  late final VoiceApi _voice = widget.voiceApi ?? VoiceApi(sl<ApiClient>());
  final _input = TextEditingController();
  bool _recording = false;
  bool _transcribing = false;
  int _seconds = 0;
  Timer? _tick;

  String get _lang => context.locale.languageCode;

  @override
  void dispose() {
    _tick?.cancel();
    if (widget.recorder == null) _rec.dispose();
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final t = _input.text.trim();
    if (t.isEmpty || widget.busy) return;
    _input.clear();
    widget.onSend(t);
  }

  Future<void> _mic() async {
    if (widget.busy || _transcribing) return;
    if (_recording) return _stop();
    if (!await _rec.requestPermission()) {
      widget.onNotice('listing.ai_mic_denied'.tr());
      return;
    }
    try {
      await _rec.start();
    } catch (_) {
      widget.onNotice('listing.ai_failed'.tr());
      return;
    }
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= 120) _stop();
    });
  }

  Future<void> _stop() async {
    _tick?.cancel();
    final secs = _seconds;
    setState(() {
      _recording = false;
      _transcribing = true;
    });
    try {
      final path = await _rec.stop();
      if (path == null || secs < 1) throw StateError('empty');
      final heard = await _voice.transcribe(
        path,
        seconds: secs,
        language: _lang,
      );
      if (!mounted) return;
      setState(() => _transcribing = false);
      if (heard.transcript.isEmpty) {
        widget.onNotice('listing.ai_nospeech'.tr());
      } else {
        widget.onSend(heard.transcript, voice: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _transcribing = false);
        widget.onNotice('listing.ai_nospeech'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final off = widget.busy || _transcribing;
    return Container(
      padding: const EdgeInsets.fromLTRB(kListPad, 10, kListPad, 16),
      decoration: const BoxDecoration(
        color: Color(0xF5FAFBFD),
        border: Border(top: BorderSide(color: JV2.line)),
      ),
      child: SafeArea(
        top: false,
        child: _recording
            ? Container(
                padding: const EdgeInsets.fromLTRB(15, 12, 12, 12),
                decoration: BoxDecoration(
                  color: JV2.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: JV2.goldEdge),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: JV2.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'listing.ai_recording'.tr(
                          args: [
                            '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: JV2.ink,
                        ),
                      ),
                    ),
                    GestureDetector(
                      key: const Key('ai-mic'),
                      onTap: _mic,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [JV2.goldHi, JV2.gold],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: JV2.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: JV2.line),
                      ),
                      child: TextField(
                        key: const Key('ai-input'),
                        controller: _input,
                        enabled: !off,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(fontSize: 14, color: JV2.ink),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.hint,
                          hintStyle: const TextStyle(color: JV2.inkMute),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    key: const Key('ai-send'),
                    onTap: _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: JV2.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: JV2.line),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const Key('ai-mic'),
                    onTap: _mic,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: off
                              ? const [JV2.fillHi, JV2.fillHi]
                              : const [JV2.navyLift, JV2.navy],
                        ),
                      ),
                      child: _transcribing
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: JV2.gold,
                              ),
                            )
                          : const Icon(
                              Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
