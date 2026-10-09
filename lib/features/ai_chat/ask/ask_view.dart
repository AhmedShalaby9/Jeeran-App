import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/widgets/jv2.dart';
import '../../compounds/presentation/pages/compound_page.dart';
import '../../explore/presentation/widgets/explore_widgets.dart' show isRtl;
import '../../news/v2/news_list_page.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/presentation/pages/property_details_page.dart';
import '../../voice/voice_services.dart';
import 'ask_api.dart';
import 'ask_history_page.dart';
import 'ask_widgets.dart';

/// Jeeran AI across the whole market: a prompt list, then a thread whose answers carry the
/// listings, compounds and news they were built on. Used as the Ask tab and, with
/// [embedded] false, as a pushed screen (e.g. "Continue in Ask").
class AskView extends StatefulWidget {
  final bool embedded;
  final int? sessionId;
  final String? sessionTitle;
  final AskApi? api; // tests inject a fake

  /// Asked as soon as the screen opens (a voice question). With a [speaker] the answer is read aloud.
  final String? initialQuestion;
  final int? voiceId;
  final VoiceSpeaker? speaker;
  const AskView({
    super.key,
    this.embedded = true,
    this.sessionId,
    this.sessionTitle,
    this.api,
    this.initialQuestion,
    this.voiceId,
    this.speaker,
  });

  @override
  State<AskView> createState() => _AskViewState();
}

class _AskViewState extends State<AskView> {
  late final AskApi _api = widget.api ?? AskApi(sl<ApiClient>());
  final _input = TextEditingController();
  final _scroll = ScrollController();

  int? _sessionId;
  String? _title;
  final List<AskTurn> _turns = [];
  bool _thinking = false;
  bool _loadingSession = false;
  String? _error;
  String? _lastQuestion;

  // typewriter for the answer that just arrived
  Timer? _typer;
  int? _typingTurn;
  int _revealed = 0;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) _open(widget.sessionId!, widget.sessionTitle);
    final q = widget.initialQuestion;
    if (q != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _send(q, voiceId: widget.voiceId),
      );
    }
  }

  @override
  void dispose() {
    _typer?.cancel();
    widget.speaker?.stop();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _lang => context.locale.languageCode;

  List<String> get _prompts => [
    'concierge.p1'.tr(),
    'concierge.p2'.tr(),
    'concierge.p3'.tr(),
    AppStorage.isSeller
        ? 'concierge.p4_seller'.tr()
        : 'concierge.p4_buyer'.tr(),
  ];

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  });

  void _reset() {
    _typer?.cancel();
    setState(() {
      _sessionId = null;
      _title = null;
      _turns.clear();
      _thinking = false;
      _error = null;
      _lastQuestion = null;
      _typingTurn = null;
    });
  }

  Future<void> _open(int id, String? title) async {
    _reset();
    setState(() {
      _sessionId = id;
      _title = title;
      _loadingSession = true;
    });
    try {
      final turns = await _api.messages(id);
      if (mounted) setState(() => _turns.addAll(turns));
      _toBottom();
    } catch (_) {
      if (mounted) setState(() => _error = 'concierge.load_failed'.tr());
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  Future<void> _send(String raw, {int? voiceId}) async {
    final q = raw.trim();
    if (q.isEmpty || _thinking) return;
    widget.speaker?.stop();
    _typer?.cancel();
    setState(() {
      _typingTurn = null;
      _turns.add(AskTurn(true, q));
      _thinking = true;
      _error = null;
      _lastQuestion = q;
      _input.clear();
    });
    _toBottom();
    try {
      if (_sessionId == null) {
        _title = q.length > 60 ? '${q.substring(0, 60)}…' : q;
        _sessionId = await _api.createSession(_title!, _lang);
      }
      final reply = await _api.send(_sessionId!, q, _lang, voiceId: voiceId);
      if (!mounted) return;
      setState(() {
        _turns.add(AskTurn(false, reply.text, reply.refs));
        _thinking = false;
        _typingTurn = _turns.length - 1;
        _revealed = 0;
      });
      _startTyping(_split(reply.text).$1.length);
      widget.speaker?.speak(_spoken(reply.text), _lang);
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _error = e.code == 'ai_limit'
            ? 'concierge.limit'.tr(
                args: ['${((e.retryAfterSeconds ?? 60) / 60).ceil()}'],
              )
            : 'concierge.send_failed'.tr();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _thinking = false;
          _error = 'concierge.send_failed'.tr();
        });
      }
    }
    _toBottom();
  }

  void _startTyping(int length) {
    _typer = Timer.periodic(const Duration(milliseconds: 26), (t) {
      if (!mounted) return t.cancel();
      setState(() => _revealed += 3);
      _toBottom();
      if (_revealed >= length) {
        t.cancel();
        setState(() => _typingTurn = null);
        _toBottom();
      }
    });
  }

  /// What is read aloud: the answer without markdown marks.
  static String _spoken(String text) => text
      .replaceAll(RegExp(r'[*_#`>]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// The first paragraph goes above the cards, anything after it below them.
  static (String, String) _split(String text) {
    final i = text.indexOf('\n\n');
    return i > 0
        ? (text.substring(0, i).trim(), text.substring(i + 2).trim())
        : (text.trim(), '');
  }

  Future<void> _history() async {
    final picked = await Navigator.push<AskHistoryResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AskHistoryPage(api: _api, currentSessionId: _sessionId),
      ),
    );
    if (!mounted || picked == null) return;
    if (picked.deletedCurrent) _reset();
    if (picked.open != null) _open(picked.open!.id, picked.open!.title);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          AskHeader(
            title: _title ?? 'concierge.title'.tr(),
            showBack: !widget.embedded,
            onHistory: _history,
            onNew: _reset,
          ),
          Expanded(
            child:
                _turns.isEmpty &&
                    !_thinking &&
                    !_loadingSession &&
                    _error == null
                ? _empty()
                : _thread(),
          ),
          AskComposer(controller: _input, disabled: _thinking, onSend: _send),
        ],
      ),
    );
  }

  Widget _empty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(kAskPad, 34, kAskPad, 26),
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [JV2.navyLift, JV2.navy],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x380B2A4A),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 14),
        Text('concierge.empty_title'.tr(), style: JV2.display(context, 30)),
        const SizedBox(height: 14),
        Text('concierge.empty_sub'.tr(), style: JV2.sub),
        const SizedBox(height: 26),
        Text(
          'concierge.try'.tr().toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: JV2.inkSub,
          ),
        ),
        const SizedBox(height: 9),
        for (final p in _prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: GestureDetector(
              onTap: () => _send(p),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
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
                          height: 1.4,
                          color: JV2.ink,
                        ),
                      ),
                    ),
                    Icon(
                      isRtl(context)
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 17,
                      color: JV2.inkSub,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _thread() {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(kAskPad, 20, kAskPad, 26),
      children: [
        if (_loadingSession)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator(color: JV2.navy)),
          ),
        for (var i = 0; i < _turns.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: _turns[i].user ? AskUserMsg(_turns[i].text) : _assistant(i),
          ),
        if (_thinking)
          const Padding(
            padding: EdgeInsets.only(bottom: 22),
            child: AskThinking(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: JV2.danger,
                  ),
                ),
                if (_lastQuestion != null && !_loadingSession) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      // the failed question is already on screen: drop it and ask again
                      if (_turns.isNotEmpty && _turns.last.user)
                        _turns.removeLast();
                      _send(_lastQuestion!);
                    },
                    child: Text(
                      'concierge.retry'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: JV2.navy,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _assistant(int i) {
    final t = _turns[i];
    final (first, tail) = _split(t.text);
    final typing = _typingTurn == i;
    return AskAssistantMsg(
      text: typing
          ? first.substring(0, _revealed.clamp(0, first.length))
          : first,
      tail: tail,
      refs: t.refs,
      typing: typing,
      onProperty: _openProperty,
      onCompound: (id, name) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompoundPage(compoundId: id, name: name),
        ),
      ),
      onNews: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewsListPage()),
      ),
    );
  }
}
