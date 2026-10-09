import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/error/exceptions.dart';
import '../../core/widgets/jv2.dart';
import '../voice/voice_api.dart';
import '../voice/voice_services.dart';
import 'listing_api.dart';
import 'listing_widgets.dart';
import 'shortcut_composer.dart';

class _Msg {
  final bool user;
  final String text;
  final List<ListingBrief> picks;
  const _Msg(this.user, this.text, {this.picks = const []});
}

/// "Change a listing price": say which listing and the new price (or "5% less"); a card shows the change;
/// one tap applies it, and Undo puts the old price back. Prices go live at once — no review.
class PriceShortcutPage extends StatefulWidget {
  final ListingApi api;
  final VoiceRecorder? recorder;
  final VoiceApi? voiceApi;
  const PriceShortcutPage({
    super.key,
    required this.api,
    this.recorder,
    this.voiceApi,
  });

  @override
  State<PriceShortcutPage> createState() => _PriceShortcutPageState();
}

class _PriceShortcutPageState extends State<PriceShortcutPage> {
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  PriceReply? _proposal;
  bool _done = false;
  bool _busy = false;
  String _lastText = '';
  int?
  _pickedId; // once the seller has said which listing, they need not say it again

  String get _lang => context.locale.languageCode;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 240,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  void _bot(String text, {List<ListingBrief> picks = const []}) =>
      _msgs.add(_Msg(false, text, picks: picks));

  String _egp(double n) => 'EGP ${grouped(n)}';

  Future<void> _send(
    String text, {
    bool voice = false,
    int? listingId,
    String? shown,
  }) async {
    final t = text.trim();
    if (t.isEmpty || _busy) return;
    setState(() {
      _msgs.add(_Msg(true, shown ?? t));
      _busy = true;
      _proposal = null;
      _done = false;
    });
    _toBottom();
    // a pick answers the question about the same request; a bare answer ("9 million") belongs to the listing already chosen
    final request = listingId != null ? _lastText : t;
    if (listingId == null) _lastText = t;
    try {
      final r = await widget.api.priceChange(
        request,
        _lang,
        listingId: listingId ?? _pickedId,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (r.listing != null) _pickedId = r.listing!.id;
        if (r.hasProposal) {
          _proposal = r;
          final pct = r.changePercent;
          final note = StringBuffer(
            'listing.price_confirm'.tr(
              args: [
                r.listing!.title,
                _egp(r.oldPrice ?? 0),
                _egp(r.newPrice!),
              ],
            ),
          );
          if (pct != null && pct.abs() >= 25) {
            note.write(
              ' ${'listing.price_big'.tr(args: [pct.abs().toStringAsFixed(0)])}',
            );
          }
          _bot(note.toString());
        } else if (r.question != null) {
          _bot(r.question!, picks: r.candidates);
        }
      });
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot(e.message ?? 'listing.ai_failed'.tr());
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot('listing.ai_failed'.tr());
        });
      }
    }
    _toBottom();
  }

  Future<void> _apply() async {
    final p = _proposal;
    if (p == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.update(p.listing!.id, {'price': p.newPrice});
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
        _pickedId = null; // the next sentence is a new request
        _bot(
          'listing.price_done'.tr(args: [p.listing!.title, _egp(p.newPrice!)]) +
              (p.savers > 0 && (p.newPrice! < (p.oldPrice ?? 0))
                  ? ' ${'listing.price_savers'.plural(p.savers)}'
                  : ''),
        );
      });
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot(e.message ?? 'listing.price_failed'.tr());
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot('listing.price_failed'.tr());
        });
      }
    }
    _toBottom();
  }

  Future<void> _undo() async {
    final p = _proposal;
    if (p == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.update(p.listing!.id, {'price': p.oldPrice});
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = false;
        _proposal = null;
        _pickedId = null;
        _bot(
          'listing.price_undone'.tr(
            args: [p.listing!.title, _egp(p.oldPrice ?? 0)],
          ),
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot('listing.price_failed'.tr());
        });
      }
    }
    _toBottom();
  }

  void _cancel() => setState(() {
    _proposal = null;
    _pickedId = null;
    _bot('listing.price_cancelled'.tr());
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(kListPad, top + 8, kListPad, 12),
            decoration: const BoxDecoration(
              color: Color(0xF0FAFBFD),
              border: Border(bottom: BorderSide(color: JV2.line)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: JV2.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: JV2.line),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: JV2.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [JV2.navyLift, JV2.navy],
                    ),
                  ),
                  child: const Center(
                    child: SparkIcon(size: 14, color: Color(0xFFE5C48F)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'listing.price_header'.tr(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                      Text(
                        'listing.ai_header_sub'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: JV2.inkSub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(kListPad, 20, kListPad, 20),
              children: [
                if (_msgs.isEmpty) ...[
                  Text(
                    'listing.price_intro'.tr(),
                    style: JV2.display(context, 26),
                  ),
                  const SizedBox(height: 12),
                  Text('listing.price_intro_sub'.tr(), style: JV2.sub),
                  const SizedBox(height: 18),
                  for (final k in const ['price_ex1', 'price_ex2'])
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: JV2.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: JV2.line),
                      ),
                      child: Text(
                        '“${'listing.$k'.tr()}”',
                        style: const TextStyle(fontSize: 13, color: JV2.ink),
                      ),
                    ),
                ],
                for (final (i, m) in _msgs.indexed) ...[
                  _bubble(m, last: i == _msgs.length - 1),
                  if (_proposal != null && i == _msgs.length - 1 && !m.user)
                    _card(),
                  if (_proposal != null &&
                      _done &&
                      i == _msgs.length - 1 &&
                      m.user)
                    const SizedBox.shrink(),
                ],
                if (_busy)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: JV2.goldHi,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'listing.ai_reading'.tr(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: JV2.inkSub,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          ShortcutComposer(
            busy: _busy,
            hint: 'listing.price_hint'.tr(),
            recorder: widget.recorder,
            voiceApi: widget.voiceApi,
            onSend: (t, {bool voice = false}) => _send(t, voice: voice),
            onNotice: (m) => setState(() => _bot(m)),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m, {required bool last}) {
    if (m.user) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsets.only(top: 14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .84,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: JV2.navy,
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(18),
              topEnd: Radius.circular(18),
              bottomStart: Radius.circular(18),
              bottomEnd: Radius.circular(6),
            ),
          ),
          child: Text(
            m.text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.text,
            style: const TextStyle(fontSize: 14, height: 1.5, color: JV2.ink),
          ),
          if (last && m.picks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in m.picks)
                    GestureDetector(
                      key: Key('pick-${c.id}'),
                      onTap: () =>
                          _send(_lastText, listingId: c.id, shown: c.label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: JV2.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: JV2.goldEdge),
                        ),
                        child: Text(
                          c.price == null
                              ? c.label
                              : '${c.label} · ${money(c.price!)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: JV2.navy,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _card() {
    final p = _proposal!;
    final pct = p.changePercent;
    final down = (p.newPrice ?? 0) < (p.oldPrice ?? 0);
    Widget row(String k, Widget v, {bool first = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: first ? null : const Border(top: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              k,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: JV2.inkSub),
            ),
          ),
          Expanded(child: v),
        ],
      ),
    );
    Widget txt(String t, {bool bold = false, Color color = JV2.ink}) => Text(
      t,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: color,
      ),
    );
    return Container(
      key: const Key('price-card'),
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _done ? const Color(0x5913794F) : JV2.line),
        boxShadow: JV2.shadowMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            color: _done ? const Color(0x0F13794F) : null,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _done ? JV2.success : JV2.navy,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: _done
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : const SparkIcon(size: 12, color: Color(0xFFE5C48F)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_done ? 'listing.card_done' : 'listing.price_change')
                            .tr()
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                          color: _done ? JV2.success : JV2.inkSub,
                        ),
                      ),
                      Text(
                        p.listing!.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
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
          row(
            'listing.price_current'.tr(),
            txt(_egp(p.oldPrice ?? 0)),
            first: false,
          ),
          row(
            'listing.price_new'.tr(),
            Row(
              children: [
                Flexible(child: txt(_egp(p.newPrice!), bold: true)),
                if (pct != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(pct.abs() < 10 ? 1 : 0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: down ? JV2.success : JV2.warnText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          row('listing.price_live'.tr(), txt('listing.price_live_value'.tr())),
          if (down && p.savers > 0)
            row(
              'listing.price_notify'.tr(),
              txt('listing.price_savers_short'.plural(p.savers)),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: JV2.line)),
            ),
            child: _done
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          'listing.price_manage'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: JV2.inkSub,
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: const Key('price-undo'),
                        onTap: _undo,
                        child: Text(
                          'listing.undo'.tr(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: JV2.navy,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: GestureDetector(
                          key: const Key('price-cancel'),
                          onTap: _cancel,
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: JV2.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: JV2.line),
                            ),
                            child: Text(
                              'listing.cancel'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: JV2.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 14,
                        child: GestureDetector(
                          key: const Key('price-apply'),
                          onTap: _apply,
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [JV2.navyLift, JV2.navy],
                              ),
                            ),
                            child: Text(
                              'listing.price_apply'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
