import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/jv2.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
import '../ask/ask_view.dart';
import 'ask_scope_api.dart';

String _lang(BuildContext c) => c.locale.languageCode;

/// The entry card on a developer, compound or unit page: names the subject and offers three ways in.
class AskContextCard extends StatefulWidget {
  final AskScope scope;
  final AskScopeApi? api; // tests inject a fake
  const AskContextCard({super.key, required this.scope, this.api});

  @override
  State<AskContextCard> createState() => _AskContextCardState();
}

class _AskContextCardState extends State<AskContextCard> {
  late final AskScopeApi _api = widget.api ?? AskScopeApi(sl<ApiClient>());
  List<String> _prompts = const [];

  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    // the same suggestions the sheet will show, so the chips on the card are real questions
    _api
        .info(widget.scope, _lang(context))
        .then((i) {
          if (mounted) setState(() => _prompts = i.prompts.take(3).toList());
        })
        .catchError((_) {});
  }

  void _open([String? question]) =>
      showAskSheet(context, widget.scope, api: _api, firstQuestion: question);

  @override
  Widget build(BuildContext context) {
    final s = widget.scope;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [JV2.navyLift, JV2.navy, Color(0xFF071D34)],
          stops: [0, 0.66, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B2A4A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _open(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0x24FFFFFF),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ask.eyebrow'
                              .tr(args: ['ask.name_${s.type.name}'.tr()])
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.9,
                            color: Color(0xFFE5C48F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ask.open_${s.type.name}'.tr(),
                          style: JV2
                              .display(context, 17)
                              .copyWith(color: Colors.white, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    chevronIcon(context),
                    size: 18,
                    color: const Color(0xB8FFFFFF),
                  ),
                ],
              ),
            ),
          ),
          if (_prompts.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
                itemCount: _prompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _open(_prompts[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x2EFFFFFF)),
                    ),
                    child: Text(
                      _prompts[i],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xEBFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }
}

/// Raises the Ask sheet over the current page. [firstQuestion] is asked as soon as it opens.
Future<void> showAskSheet(
  BuildContext context,
  AskScope scope, {
  AskScopeApi? api,
  String? firstQuestion,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x570B2A4A),
    builder: (_) => AskContextSheet(
      scope: scope,
      api: api ?? AskScopeApi(sl<ApiClient>()),
      firstQuestion: firstQuestion,
    ),
  );
}

class _Turn {
  final bool user;
  final String text;
  final List<(String, String)> facts;
  const _Turn(this.user, this.text, [this.facts = const []]);
}

class AskContextSheet extends StatefulWidget {
  final AskScope scope;
  final AskScopeApi api;
  final String? firstQuestion;
  const AskContextSheet({
    super.key,
    required this.scope,
    required this.api,
    this.firstQuestion,
  });

  @override
  State<AskContextSheet> createState() => _AskContextSheetState();
}

class _AskContextSheetState extends State<AskContextSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ScopeInfo? _info;
  bool _infoFailed = false;
  final List<_Turn> _turns = [];
  int? _sessionId;
  bool _widened = false;
  bool _thinking = false;
  String? _error;
  AskLimit? _limit;

  AskScope get _scope => widget.scope;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _loadInfo();
    if (widget.firstQuestion != null)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ask(widget.firstQuestion!),
      );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    setState(() => _infoFailed = false);
    try {
      final i = await widget.api.info(_scope, _lang(context));
      if (mounted) {
        setState(() {
          _info = i;
          _limit = i.limit;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _infoFailed = true);
    }
  }

  Future<void> _ask(String text) async {
    final q = text.trim();
    if (q.isEmpty || _thinking) return;
    final lang = _lang(context);
    setState(() {
      _turns.add(_Turn(true, q));
      _thinking = true;
      _error = null;
      _input.clear();
    });
    _toBottom();
    try {
      _sessionId ??= await widget.api.createSession(
        _widened ? null : _scope,
        lang,
      );
      final reply = await widget.api.send(_sessionId!, q, lang);
      if (!mounted) return;
      setState(() {
        _turns.add(_Turn(false, reply.reply, reply.facts));
        _limit = reply.limit ?? _limit;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code == 'ai_limit'
            ? 'ask.limit_reached'.tr(
                args: ['${((e.retryAfterSeconds ?? 60) / 60).ceil()}'],
              )
            : 'ask.failed'.tr();
        if (e.code == 'ai_limit') _limit = AskLimit(_limit?.limit ?? 0, 0);
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'ask.failed'.tr());
    } finally {
      if (mounted) setState(() => _thinking = false);
      _toBottom();
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients)
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
  });

  /// Drops the scope. The conversation so far stays; later answers come from the whole market.
  Future<void> _widen() async {
    setState(() => _widened = true);
    final id = _sessionId;
    if (id != null) {
      try {
        await widget.api.widen(id);
      } catch (_) {}
    }
  }

  void _openAsk() {
    final id = _sessionId;
    final nav = Navigator.of(context);
    nav.pop();
    if (id == null) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => AskView(
          embedded: false,
          sessionId: id,
          sessionTitle: _info?.name ?? _scope.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = _scope.type.name;
    final label = _widened ? 'ask.wide_label'.tr() : _scope.name;
    final noLeft =
        _limit != null && _limit!.limit > 0 && _limit!.remaining <= 0;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          decoration: const BoxDecoration(
            color: JV2.bgDeep,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x3D0B2A4A),
                blurRadius: 50,
                offset: Offset(0, -20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: JV2.track,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ask.open_$type'.tr(),
                                style: JV2.display(context, 21),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _widened
                                    ? 'ask.wide_hint'.tr()
                                    : 'ask.hint_$type'.tr(),
                                style: JV2.sub.copyWith(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: JV2.surface,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: JV2.line),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: JV2.inkSub,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ScopePill(
                      kind: 'ask.kind_$type'.tr(),
                      title: _widened
                          ? 'ask.pill_wide'.tr()
                          : 'ask.pill_only'.tr(args: [_scope.name]),
                      sub: _widened ? null : _info?.source,
                      action: _widened ? 'ask.open_ask'.tr() : 'ask.widen'.tr(),
                      onAction: _widened
                          ? (_sessionId == null
                                ? () => Navigator.pop(context)
                                : _openAsk)
                          : _widen,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  shrinkWrap: true,
                  children: _turns.isEmpty ? _empty() : _conversation(label),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  MediaQuery.of(context).padding.bottom + 14,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: JV2.line)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: JV2.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Container(
                      height: 48,
                      padding: const EdgeInsetsDirectional.only(
                        start: 14,
                        end: 6,
                      ),
                      decoration: BoxDecoration(
                        color: JV2.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: JV2.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _input,
                              enabled: !noLeft,
                              textInputAction: TextInputAction.send,
                              onSubmitted: _ask,
                              style: const TextStyle(
                                fontSize: 14,
                                color: JV2.ink,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'ask.input_hint'.tr(args: [label]),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: noLeft ? null : () => _ask(_input.text),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [JV2.goldHi, JV2.gold],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x4DB8893D),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                noLeft
                                    ? Icons.hourglass_empty_rounded
                                    : Icons.arrow_upward_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_limit != null &&
                        _limit!.limit > 0 &&
                        _limit!.remaining <= 5 &&
                        _limit!.remaining > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'ask.left'.plural(_limit!.remaining),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: JV2.inkMute,
                          ),
                        ),
                      ),
                    if (!_widened &&
                        _turns.any((t) => !t.user) &&
                        _sessionId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: () async {
                            await _widen();
                            _openAsk();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'ask.continue_ask'.tr(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: JV2.navy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                chevronIcon(context),
                                size: 13,
                                color: JV2.navy,
                              ),
                            ],
                          ),
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

  List<Widget> _empty() {
    if (_widened)
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text('ask.wide_hint'.tr(), style: JV2.sub),
        ),
      ];
    if (_infoFailed) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text('ask.load_failed'.tr(), style: JV2.sub),
              const SizedBox(height: 12),
              JV2PrimaryButton(
                width: 150,
                height: 44,
                onPressed: _loadInfo,
                child: Text('ask.retry'.tr()),
              ),
            ],
          ),
        ),
      ];
    }
    if (_info == null) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: CircularProgressIndicator(color: JV2.navy, strokeWidth: 2),
          ),
        ),
      ];
    }
    return [
      if (_info!.prompts.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'ask.try'.tr().toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: JV2.inkMute,
            ),
          ),
        ),
      for (final p in _info!.prompts)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _ask(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JV2.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: JV2.ink,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Icon(chevronIcon(context), size: 14, color: JV2.inkMute),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _conversation(String label) {
    return [
      for (final t in _turns)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: t.user
              ? _UserBubble(t.text)
              : _AssistantBubble(t.text, t.facts),
        ),
      if (_thinking)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: JV2.goldHi,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ask.reading'.tr(args: [label]),
                style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
              ),
            ],
          ),
        ),
    ];
  }
}

class _ScopePill extends StatelessWidget {
  final String kind;
  final String title;
  final String? sub;
  final String action;
  final VoidCallback onAction;
  const _ScopePill({
    required this.kind,
    required this.title,
    required this.sub,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: JV2.goldFilm,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: JV2.goldEdge),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x29B8893D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              kind,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: JV2.gold,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
                if (sub != null && sub!.isNotEmpty)
                  Text(
                    sub!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: JV2.inkSub),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x24B8893D),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: JV2.goldEdge),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: JV2.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble(this.text);

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: JV2.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          color: Colors.white,
          height: 1.35,
        ),
      ),
    ),
  );
}

class _AssistantBubble extends StatelessWidget {
  final String text;
  final List<(String, String)> facts;
  const _AssistantBubble(this.text, this.facts);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                color: JV2.navy,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: JV2.ink,
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: JV2.ink,
                  ),
                  listBullet: const TextStyle(fontSize: 13.5, color: JV2.ink),
                ),
              ),
            ),
          ],
        ),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 38),
            child: Container(
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JV2.line),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < facts.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: JV2.inkSub,
                              ),
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
            ),
          ),
        ],
      ],
    );
  }
}
