import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/widgets/jv2.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
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

class AskComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool disabled;
  final ValueChanged<String> onSend;
  const AskComposer({
    super.key,
    required this.controller,
    required this.disabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        kAskPad,
        12,
        kAskPad,
        12 + (MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 0),
      ),
      decoration: const BoxDecoration(
        color: Color(0xEBFAFBFD),
        border: Border(top: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: JV2.line),
              ),
              child: TextField(
                controller: controller,
                enabled: !disabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                style: const TextStyle(fontSize: 14.5, color: JV2.ink),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'concierge.input_hint'.tr(),
                  hintStyle: const TextStyle(color: JV2.inkSub),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: disabled ? null : () => onSend(controller.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: disabled
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [JV2.navyLift, JV2.navy],
                      ),
                color: disabled ? JV2.fillHi : null,
                boxShadow: disabled
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x3D0B2A4A),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
              ),
              child: Icon(
                isRtl(context)
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_forward_rounded,
                size: 19,
                color: disabled ? JV2.inkMute : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

  const AskAssistantMsg({
    super.key,
    required this.text,
    required this.tail,
    required this.refs,
    required this.typing,
    required this.onProperty,
    required this.onCompound,
    required this.onNews,
  });

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
                if (done && refs.properties.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _PropertyRail(items: refs.properties, onTap: onProperty),
                ],
                if (done && refs.projects.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Label('concierge.compounds'.tr()),
                  const SizedBox(height: 8),
                  _CompoundChips(items: refs.projects, onTap: onCompound),
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

class _PropertyRail extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onTap;
  const _PropertyRail({required this.items, required this.onTap});

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

class _CompoundChips extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(int id, String name) onTap;
  const _CompoundChips({required this.items, required this.onTap});

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
