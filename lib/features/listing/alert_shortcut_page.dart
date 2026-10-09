import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/error/exceptions.dart';
import '../../core/widgets/jv2.dart';
import '../voice/voice_api.dart';
import '../voice/voice_services.dart';
import 'listing_widgets.dart';
import 'price_alert_api.dart';
import 'shortcut_composer.dart';

class _Msg {
  final bool user;
  final String text;
  const _Msg(this.user, this.text);
}

/// "Set a price alert": say what to watch and the limit; a card shows the alert; one tap turns it on and Undo removes it.
/// Buyers need nothing else — the notification arrives when a unit goes live or drops under the limit.
class AlertShortcutPage extends StatefulWidget {
  final PriceAlertApi api;
  final VoiceRecorder? recorder;
  final VoiceApi? voiceApi;
  const AlertShortcutPage({
    super.key,
    required this.api,
    this.recorder,
    this.voiceApi,
  });

  @override
  State<AlertShortcutPage> createState() => _AlertShortcutPageState();
}

class _AlertShortcutPageState extends State<AlertShortcutPage> {
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  AlertReply? _reply; // the alert as understood so far
  PriceAlertDraft? _prev; // sent back so the next sentence corrects it
  SavedAlert? _saved; // set once it is on
  bool _busy = false;

  String get _lang => context.locale.languageCode;
  bool get _ar => _lang == 'ar';

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

  void _bot(String t) => _msgs.add(_Msg(false, t));

  String _egp(double n) => 'EGP ${money(n)}';

  /// "Two units are at 11.2M right now…" — only real numbers.
  String _marketLine(AlertReply r) {
    final n = r.now;
    final limit = r.alert.maxPrice;
    if (n == null || limit == null || n.total == 0)
      return 'listing.alert_none_live'.tr();
    if (n.underCount > 0) {
      return 'listing.alert_under_now'.tr(
        args: ['${n.underCount}', _egp(limit), _egp(n.cheapest!)],
      );
    }
    return 'listing.alert_none_under'.tr(
      args: [_egp(n.cheapest!), _egp(limit)],
    );
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _busy) return;
    setState(() {
      _msgs.add(_Msg(true, t));
      _busy = true;
      _saved = null;
    });
    _toBottom();
    try {
      final r = await widget.api.parse(t, _prev, _lang);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _prev = r.alert;
        if (r.unknownCompound) {
          _reply = null;
          _bot('listing.ai_unknown_compound'.tr());
        } else if (!r.complete) {
          _reply = null;
          _bot(r.question ?? 'listing.ai_failed'.tr());
        } else {
          _reply = r;
          _bot('${_marketLine(r)} ${'listing.alert_turn_on_q'.tr()}');
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

  Future<void> _turnOn() async {
    final r = _reply;
    if (r == null || _busy) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.create(r.alert);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _saved = saved;
        _bot('listing.alert_done'.tr(args: [_egp(r.alert.maxPrice ?? 0)]));
      });
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot(e.message ?? 'listing.alert_failed'.tr());
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot('listing.alert_failed'.tr());
        });
      }
    }
    _toBottom();
  }

  Future<void> _undo() async {
    final s = _saved;
    if (s == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.remove(s.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _saved = null;
        _reply = null;
        _prev = null;
        _bot('listing.alert_removed'.tr());
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot('listing.alert_failed'.tr());
        });
      }
    }
    _toBottom();
  }

  void _change() => setState(() {
    _reply = null;
    _bot('listing.alert_change_prompt'.tr());
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
                        'listing.alert_header'.tr(),
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
                    'listing.alert_intro'.tr(),
                    style: JV2.display(context, 26),
                  ),
                  const SizedBox(height: 12),
                  Text('listing.alert_intro_sub'.tr(), style: JV2.sub),
                  const SizedBox(height: 18),
                  for (final k in const ['alert_ex1', 'alert_ex2'])
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
                  _bubble(m),
                  if (_reply != null && i == _msgs.length - 1 && !m.user)
                    _card(_reply!),
                  if (_saved != null &&
                      i == _msgs.length - 1 &&
                      !m.user &&
                      _reply != null)
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
            onSend: (t, {bool voice = false}) => _send(t),
            onNotice: (m) => setState(() => _bot(m)),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m) {
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
      child: Text(
        m.text,
        style: const TextStyle(fontSize: 14, height: 1.5, color: JV2.ink),
      ),
    );
  }

  Widget _card(AlertReply r) {
    final a = r.alert;
    final done = _saved != null;
    final c = r.compound;
    final rows = <(String, String)>[
      if (c != null) ('listing.f_compound'.tr(), c.name(_ar)),
      if (a.propertyType != null)
        ('listing.f_type'.tr(), 'listing.t_${a.propertyType}'.tr()),
      if (a.minBedrooms != null) ('listing.f_beds'.tr(), '${a.minBedrooms}+'),
      (
        'listing.f_price'.tr(),
        'listing.alert_under'.tr(args: [_egp(a.maxPrice ?? 0)]),
      ),
      ('listing.alert_notify'.tr(), 'listing.alert_notify_value'.tr()),
    ];
    return Container(
      key: const Key('alert-card'),
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: done ? const Color(0x5913794F) : JV2.line),
        boxShadow: JV2.shadowMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            color: done ? const Color(0x0F13794F) : null,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done ? JV2.success : JV2.navy,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: done
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
                        (done ? 'listing.card_done' : 'listing.alert_new')
                            .tr()
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                          color: done ? JV2.success : JV2.inkSub,
                        ),
                      ),
                      Text(
                        [
                          if (a.minBedrooms != null)
                            'listing.alert_beds'.tr(args: ['${a.minBedrooms}']),
                          if (c != null)
                            c.name(_ar)
                          else if (a.propertyType != null)
                            'listing.t_${a.propertyType}'.tr(),
                          'listing.alert_under'.tr(
                            args: [_egp(a.maxPrice ?? 0)],
                          ),
                        ].join(' · '),
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
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: JV2.line)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      row.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: JV2.inkSub),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.check_rounded, size: 13, color: JV2.success),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: JV2.line)),
            ),
            child: done
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          'listing.alert_manage'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: JV2.inkSub,
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: const Key('alert-undo'),
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
                          key: const Key('alert-change'),
                          onTap: _change,
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: JV2.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: JV2.line),
                            ),
                            child: Text(
                              'listing.change'.tr(),
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
                          key: const Key('alert-on'),
                          onTap: _turnOn,
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
                              'listing.alert_turn_on'.tr(),
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
