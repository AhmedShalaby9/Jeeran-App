import 'dart:ui' show FontFeature;
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/widgets/jv2.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
import '../../units/data/unit_format.dart';
import '../../units/presentation/unit_widgets.dart';
import '../../../core/di/injection_container.dart';
import '../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../follow/data/follow_service.dart';
import 'ask_api.dart';

const double kAskPad = 20;

// ── header ───────────────────────────────────────────────

class AskHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback onHistory;
  final VoidCallback onNew;
  const AskHeader({
    super.key,
    required this.title,
    required this.onHistory,
    required this.onNew,
    this.showBack = false,
  });

  Widget _btn(BuildContext c, IconData icon, String tip, VoidCallback onTap) =>
      Tooltip(
        message: tip,
        child: GestureDetector(
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
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        kAskPad,
        MediaQuery.of(context).padding.top + 8,
        kAskPad,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xE6FAFBFD),
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _btn(
              context,
              isRtl(context)
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              'concierge.back'.tr(),
              () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: JV2.success,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'concierge.reading_live'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: JV2.inkSub),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _btn(
            context,
            Icons.history_rounded,
            'concierge.history'.tr(),
            onHistory,
          ),
          const SizedBox(width: 10),
          _btn(context, Icons.add_rounded, 'concierge.new_chat'.tr(), onNew),
        ],
      ),
    );
  }
}

// ── composer ─────────────────────────────────────────────

/// What the composer is doing with the microphone.
enum AskVoice { idle, recording, transcribing }

class AskComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool disabled;
  final ValueChanged<String> onSend;

  /// Voice notes: null hides the microphone. While [voice] is recording the field becomes a recorder.
  final AskVoice voice;
  final int seconds;
  final VoidCallback? onMic, onCancelVoice, onSendVoice;
  const AskComposer({
    super.key,
    required this.controller,
    required this.disabled,
    required this.onSend,
    this.voice = AskVoice.idle,
    this.seconds = 0,
    this.onMic,
    this.onCancelVoice,
    this.onSendVoice,
  });

  static String _clock(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _roundBtn({
    Key? key,
    required IconData icon,
    required VoidCallback? onTap,
    bool primary = false,
    Color? color,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: primary && onTap != null
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [JV2.navyLift, JV2.navy],
                )
              : null,
          color: primary ? (onTap == null ? JV2.fillHi : null) : JV2.surface,
          border: primary ? null : Border.all(color: JV2.line),
          boxShadow: primary && onTap != null
              ? const [
                  BoxShadow(
                    color: Color(0x3D0B2A4A),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: primary
              ? (onTap == null ? JV2.inkMute : Colors.white)
              : (color ?? JV2.ink),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recording = voice == AskVoice.recording;
    final transcribing = voice == AskVoice.transcribing;
    return Container(
      padding: const EdgeInsets.fromLTRB(kAskPad, 12, kAskPad, 12),
      decoration: const BoxDecoration(
        color: Color(0xEBFAFBFD),
        border: Border(top: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          if (recording) ...[
            _roundBtn(
              key: const Key('voice-cancel'),
              icon: Icons.close_rounded,
              onTap: onCancelVoice,
              color: JV2.danger,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: recording
                      ? JV2.danger.withValues(alpha: 0.5)
                      : JV2.line,
                ),
              ),
              child: recording
                  ? AskRecordingStrip(seconds: seconds)
                  : transcribing
                  ? const AskTranscribingStrip()
                  : TextField(
                      controller: controller,
                      enabled: !disabled,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: onSend,
                      style: const TextStyle(fontSize: 14.5, color: JV2.ink),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintText: 'concierge.input_hint'.tr(),
                        hintStyle: const TextStyle(color: JV2.inkSub),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          if (recording)
            _roundBtn(
              key: const Key('voice-send'),
              icon: Icons.check_rounded,
              onTap: onSendVoice,
              primary: true,
            )
          else ...[
            if (onMic != null) ...[
              _roundBtn(
                key: const Key('ask-mic'),
                icon: Icons.mic_none_rounded,
                onTap: disabled || transcribing ? null : onMic,
              ),
              const SizedBox(width: 8),
            ],
            _roundBtn(
              key: const Key('ask-send'),
              icon: isRtl(context)
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
              onTap: disabled || transcribing
                  ? null
                  : () => onSend(controller.text),
              primary: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// A red dot that breathes while the microphone is open.
/// What the input shows while a voice note is being recorded: a pulsing dot, the clock, "Listening…".
class AskRecordingStrip extends StatelessWidget {
  final int seconds;
  const AskRecordingStrip({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) => Row(
    key: const Key('ask-recording'),
    children: [
      const _RecDot(),
      const SizedBox(width: 10),
      Text(
        AskComposer._clock(seconds),
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: JV2.ink,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'voice.listening'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: JV2.inkSub),
        ),
      ),
    ],
  );
}

/// What the input shows while the recording is turned into text.
class AskTranscribingStrip extends StatelessWidget {
  const AskTranscribingStrip({super.key});

  @override
  Widget build(BuildContext context) => Row(
    key: const Key('ask-transcribing'),
    children: [
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: JV2.navy),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'voice.transcribing'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, color: JV2.inkSub),
        ),
      ),
    ],
  );
}

class _RecDot extends StatefulWidget {
  const _RecDot();

  @override
  State<_RecDot> createState() => _RecDotState();
}

class _RecDotState extends State<_RecDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
    child: Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: JV2.danger,
        shape: BoxShape.circle,
      ),
    ),
  );
}

// ── messages ─────────────────────────────────────────────

class AskUserMsg extends StatelessWidget {
  final String text;
  const AskUserMsg(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 46),
    child: Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [JV2.navyLift, JV2.navy],
          ),
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(18),
            topEnd: Radius.circular(18),
            bottomStart: Radius.circular(18),
            bottomEnd: Radius.circular(6),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E0B2A4A),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

class AskAvatar extends StatelessWidget {
  const AskAvatar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    margin: const EdgeInsets.only(top: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(11),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [JV2.navyLift, JV2.navy],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x330B2A4A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: const Icon(
      Icons.auto_awesome_rounded,
      size: 15,
      color: Colors.white,
    ),
  );
}

class AskThinking extends StatefulWidget {
  const AskThinking({super.key});

  @override
  State<AskThinking> createState() => _AskThinkingState();
}

class _AskThinkingState extends State<AskThinking>
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AskAvatar(),
        const SizedBox(width: 11),
        Flexible(
          child: Text(
            'concierge.step'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: JV2.inkSub),
          ),
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
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: JV2.goldHi.withValues(
                      alpha:
                          0.3 +
                          0.7 *
                              (0.5 +
                                  0.5 *
                                      math.sin(
                                        _c.value * 2 * math.pi - i * 0.9,
                                      )),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The assistant's reply: attribution line, the first paragraph, the cards it read, then the rest.
class AskAssistantMsg extends StatelessWidget {
  final String text; // may be partial while it types out
  final String tail;
  final AskRefs refs;
  final bool typing;
  final void Function(Map<String, dynamic> property) onProperty;
  final void Function(int compoundId, String name) onCompound;
  final VoidCallback onNews;
  final void Function(String text)?
  onAnswer; // taps on the question buttons send this as the next message
  final bool canAnswer; // only the latest answer takes taps

  const AskAssistantMsg({
    super.key,
    required this.text,
    required this.tail,
    required this.refs,
    required this.typing,
    required this.onProperty,
    required this.onCompound,
    required this.onNews,
    this.onAnswer,
    this.canAnswer = false,
  });

  /// Units shown by a plan card are not shown a second time in the rail.
  List<Map<String, dynamic>> get _railItems {
    final shown = {for (final p in refs.plans) p.propertyId};
    return [
      for (final p in refs.properties)
        if (!shown.contains(p['id'] is num ? (p['id'] as num).toInt() : -1)) p,
    ];
  }

  static String sourcesOf(AskRefs r) => [
    if (r.properties.isNotEmpty)
      'concierge.s_listings'.plural(r.properties.length),
    if (r.projects.isNotEmpty)
      'concierge.s_compounds'.plural(r.projects.length),
    if (r.news.isNotEmpty) 'concierge.s_news'.plural(r.news.length),
  ].join(' · ');

  Widget _md(String data) => MarkdownBody(
    data: data,
    styleSheet: MarkdownStyleSheet(
      p: const TextStyle(fontSize: 14.5, height: 1.55, color: JV2.ink),
      strong: const TextStyle(fontWeight: FontWeight.w800, color: JV2.ink),
      listBullet: const TextStyle(fontSize: 14.5, color: JV2.ink),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sources = sourcesOf(refs);
    final done = !typing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AskAvatar(),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sources.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: JV2.goldHi,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          sources,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: JV2.inkSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                _md(typing ? '$text▍' : text),
                // questions to collect what it needs before searching: tap, then Send
                if (done && refs.questions.isNotEmpty && onAnswer != null) ...[
                  const SizedBox(height: 14),
                  AskQuestionsCard(
                    questions: refs.questions,
                    enabled: canAnswer,
                    onSend: onAnswer!,
                  ),
                ],
                // what the assistant did for the person, each with an Undo
                if (done && refs.actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AskActionChips(actions: refs.actions),
                ],
                // a plan the assistant quoted: the same summary card as the property page, then the unit it belongs to
                if (done && refs.plans.isNotEmpty)
                  for (final p in refs.plans) ...[
                    const SizedBox(height: 14),
                    AskPlanCard(ref: p, onTap: onProperty),
                  ],
                if (done && _railItems.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AskPropertyRail(items: _railItems, onTap: onProperty),
                ],
                if (done && refs.projects.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Label('concierge.compounds'.tr()),
                  const SizedBox(height: 8),
                  AskCompoundChips(items: refs.projects, onTap: onCompound),
                ],
                if (done && refs.news.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Label('concierge.news'.tr()),
                  const SizedBox(height: 8),
                  _NewsChips(items: refs.news, onTap: onNews),
                ],
                if (done && refs.facts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AskFactStrip(refs.facts),
                ],
                if (done && tail.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _md(tail),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: JV2.inkSub,
    ),
  );
}

String _pick(BuildContext c, Map<String, dynamic> m, String key) {
  final ar = (m['${key}_ar'] as String?) ?? '';
  final en = (m['${key}_en'] as String?) ?? '';
  return isArabic(c) ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
}

/// The assistant's questions with tappable answers. One answer per question (tap again to clear); "Send" sends them together,
/// "Show me anything" skips the questions. The person can always type instead.
class AskQuestionsCard extends StatefulWidget {
  final List<AskQuestion> questions;
  final bool enabled;
  final void Function(String text) onSend;
  const AskQuestionsCard({
    super.key,
    required this.questions,
    required this.enabled,
    required this.onSend,
  });

  @override
  State<AskQuestionsCard> createState() => _AskQuestionsCardState();
}

class _AskQuestionsCardState extends State<AskQuestionsCard> {
  final Map<int, String> _picked = {};
  bool _sent = false;

  bool get _live => widget.enabled && !_sent;

  void _send() {
    if (!_live || _picked.isEmpty) return;
    final text = [
      for (final e
          in (_picked.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        '${widget.questions[e.key].question} ${e.value}',
    ].join('\n');
    setState(() => _sent = true);
    widget.onSend(text);
  }

  void _anything() {
    if (!_live) return;
    setState(() => _sent = true);
    widget.onSend('concierge.q_anything_text'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ask-questions'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JV2.line),
        boxShadow: JV2.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.questions.length; i++) ...[
            Text(
              widget.questions[i].question,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JV2.ink,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in widget.questions[i].options)
                  GestureDetector(
                    key: Key('q$i-$o'),
                    onTap: _live
                        ? () => setState(
                            () => _picked[i] == o
                                ? _picked.remove(i)
                                : _picked[i] = o,
                          )
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _picked[i] == o
                            ? JV2.navy
                            : (_live ? JV2.surface : JV2.fillFaint),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: _picked[i] == o ? JV2.navy : JV2.line,
                        ),
                      ),
                      child: Text(
                        o,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _picked[i] == o
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _picked[i] == o
                              ? Colors.white
                              : (_live ? JV2.ink : JV2.inkMute),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (i < widget.questions.length - 1) const SizedBox(height: 14),
          ],
          if (_live) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                  key: const Key('q-anything'),
                  onTap: _anything,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'concierge.q_anything'.tr(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: JV2.inkSub,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 110,
                  child: JV2PrimaryButton(
                    key: const Key('q-send'),
                    height: 40,
                    onPressed: _picked.isEmpty ? null : _send,
                    child: Text(
                      'concierge.q_send'.tr(),
                      style: const TextStyle(fontSize: 14),
                    ),
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

/// "Following Marassi · Undo": what the assistant did on the person's behalf. Following means every notification; saving
/// files the unit under Saved. Undo reverses exactly that one action.
class AskActionChips extends StatefulWidget {
  final List<AskAction> actions;
  const AskActionChips({super.key, required this.actions});

  @override
  State<AskActionChips> createState() => _AskActionChipsState();
}

class _AskActionChipsState extends State<AskActionChips> {
  final Set<int> _undone = {};
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    // the heart on every card follows what the assistant just did (the server already did it)
    final bloc = sl.isRegistered<FavoritesBloc>() ? sl<FavoritesBloc>() : null;
    for (final a in widget.actions) {
      if (a.entityType != 'property') continue;
      if (a.action == 'save') bloc?.add(AddFavoriteEvent(a.entityId));
      if (a.action == 'unsave') bloc?.add(RemoveFavoriteEvent(a.entityId));
    }
  }

  FollowType _type(AskAction a) =>
      a.entityType == 'developer' ? FollowType.developer : FollowType.project;

  Future<void> _undo(int i) async {
    final a = widget.actions[i];
    if (_busy.contains(i) || _undone.contains(i)) return;
    setState(() => _busy.add(i));
    try {
      switch (a.action) {
        case 'follow':
          await sl<FollowService>().unfollow(_type(a), a.entityId);
        case 'unfollow':
          await sl<FollowService>().follow(_type(a), a.entityId);
        case 'save':
          sl<FavoritesBloc>().add(RemoveFavoriteEvent(a.entityId));
        case 'unsave':
          sl<FavoritesBloc>().add(AddFavoriteEvent(a.entityId));
      }
      if (mounted) setState(() => _undone.add(i));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('concierge.act_undo_failed'.tr())),
        );
    } finally {
      if (mounted) setState(() => _busy.remove(i));
    }
  }

  String _text(AskAction a, bool ar) {
    final n = a.name(ar);
    final key = a.changed
        ? 'concierge.act_${a.action}'
        : 'concierge.act_${a.action}_same';
    return key.tr(namedArgs: {'name': n});
  }

  IconData _icon(AskAction a) => switch (a.action) {
    'follow' => Icons.notifications_active_rounded,
    'save' => Icons.favorite_rounded,
    _ => Icons.check_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.actions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              key: Key('ask-action-$i'),
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: _undone.contains(i) ? JV2.fillFaint : JV2.goldFilm,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _undone.contains(i) ? JV2.line : JV2.goldEdge,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _undone.contains(i)
                        ? Icons.undo_rounded
                        : _icon(widget.actions[i]),
                    size: 17,
                    color: _undone.contains(i) ? JV2.inkSub : JV2.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _undone.contains(i)
                          ? 'concierge.act_undone'.tr()
                          : _text(widget.actions[i], ar),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _undone.contains(i) ? JV2.inkSub : JV2.ink,
                      ),
                    ),
                  ),
                  if (widget.actions[i].changed && !_undone.contains(i))
                    GestureDetector(
                      key: Key('ask-undo-$i'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _undo(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: _busy.contains(i)
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: JV2.gold,
                                ),
                              )
                            : Text(
                                'concierge.act_undo'.tr(),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: JV2.gold,
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

/// "Down payment, instalments, lump sums" for the unit the answer is about, then a row to open the unit.
class AskPlanCard extends StatelessWidget {
  final AskPlanRef ref;
  final void Function(Map<String, dynamic>) onTap;
  const AskPlanCard({super.key, required this.ref, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final price = double.tryParse('${ref.property['price'] ?? ''}');
    final title = _pick(context, ref.property, 'title');
    final images = ref.property['images'];
    final image = images is List && images.isNotEmpty && images.first is String
        ? images.first as String
        : null;
    final date = ref.publishedOn == null
        ? null
        : DateFormat(
            'd MMM y',
            context.locale.toString(),
          ).format(ref.publishedOn!);
    return Column(
      key: Key('ask-plan-${ref.propertyId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlanSummary(
          plan: ref.plan,
          headline: price,
          deliveryYear: ref.deliveryYear,
          compact: true,
        ),
        const SizedBox(height: 10),
        GestureDetector(
          key: Key('ask-plan-open-${ref.propertyId}'),
          onTap: () => onTap(ref.property),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: JV2.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: JV2.line),
            ),
            child: Row(
              children: [
                Photo(url: image, width: 58, height: 48, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (price != null)
                            '${'unit.egp'.tr()} ${fmtShort(price)}',
                          if (ref.plansCount > 1)
                            'unit.see_all_plans'.tr(
                              namedArgs: {'n': '${ref.plansCount}'},
                            ),
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: JV2.inkSub,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  ar ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: JV2.inkMute,
                ),
              ],
            ),
          ),
        ),
        if (date != null) ...[
          const SizedBox(height: 8),
          Text(
            'unit.published_figures'.tr(namedArgs: {'date': date}),
            style: const TextStyle(fontSize: 11.5, color: JV2.inkMute),
          ),
        ],
      ],
    );
  }
}

class AskPropertyRail extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onTap;
  const AskPropertyRail({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern(context.locale.toString());
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = items[i];
          final images = p['images'];
          final image =
              images is List && images.isNotEmpty && images.first is String
              ? images.first as String
              : null;
          final price = double.tryParse('${p['price'] ?? ''}');
          final size = double.tryParse('${p['size'] ?? ''}');
          final c = p['compound'] ?? p['project'];
          final cName = c is Map<String, dynamic>
              ? _pick(context, c, 'name')
              : '';
          return GestureDetector(
            onTap: () => onTap(p),
            child: Container(
              width: 152,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: JV2.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Photo(
                    url: image,
                    height: 84,
                    width: double.infinity,
                    radius: 0,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price == null ? '—' : nf.format(price.round()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JV2.display(context, 16.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pick(context, p, 'title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: JV2.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            cName,
                            if (size != null)
                              '${size.round()} ${'explore.sqm'.tr()}',
                          ].where((x) => x.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: JV2.inkSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AskCompoundChips extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(int id, String name) onTap;
  const AskCompoundChips({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in items)
          if (c['id'] is num)
            GestureDetector(
              onTap: () =>
                  onTap((c['id'] as num).toInt(), _pick(context, c, 'name')),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width - kAskPad * 2 - 41,
                ),
                padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 12, 6),
                decoration: BoxDecoration(
                  color: JV2.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: JV2.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Photo(
                      url: c['main_image'] as String?,
                      width: 24,
                      height: 24,
                      radius: 12,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _pick(context, c, 'name'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                    ),
                    if (c['developer'] is Map<String, dynamic>) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _pick(
                            context,
                            c['developer'] as Map<String, dynamic>,
                            'name',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: JV2.inkSub,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(chevronIcon(context), size: 12, color: JV2.inkSub),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _NewsChips extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onTap;
  const _NewsChips({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final n in items.take(3))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JV2.line),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 16,
                    color: JV2.inkSub,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _pick(context, n, 'title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// The numbers an answer reasoned from, as a small table.
class AskFactStrip extends StatelessWidget {
  final List<(String, String)> facts;
  const AskFactStrip(this.facts, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: JV2.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: JV2.line),
    ),
    child: Column(
      children: [
        for (var i = 0; i < facts.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : const Border(top: BorderSide(color: JV2.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    facts[i].$1,
                    style: const TextStyle(fontSize: 12, color: JV2.inkSub),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  facts[i].$2,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
