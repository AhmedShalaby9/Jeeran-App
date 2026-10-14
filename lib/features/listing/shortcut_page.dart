import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/injection_container.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/jv2.dart';
import '../voice/voice_api.dart';
import '../voice/voice_services.dart';
import 'listing_api.dart';
import 'listing_draft.dart';
import 'listing_widgets.dart';
import 'shortcut_fields.dart';

class _Msg {
  final bool user;
  final String text;
  final bool voice;
  final List<String> replies;
  const _Msg(
    this.user,
    this.text, {
    this.voice = false,
    this.replies = const [],
  });
}

/// "Tell Jeeran": say or type the listing; it fills the draft and asks only for what's missing.
/// The card shows exactly what will go into the form — nothing is published from here.
class ShortcutPage extends StatefulWidget {
  final ListingDraft draft;
  final ListingApi api;
  final VoiceRecorder? recorder;
  final VoiceApi? voiceApi;
  final VoidCallback onClose;
  final VoidCallback onReview;

  final VoidCallback onOpenForm;
  const ShortcutPage({
    super.key,
    required this.draft,
    required this.api,
    required this.onClose,
    required this.onReview,
    required this.onOpenForm,
    this.recorder,
    this.voiceApi,
  });

  @override
  State<ShortcutPage> createState() => _ShortcutPageState();
}

class _ShortcutPageState extends State<ShortcutPage> {
  late final VoiceRecorder _rec = widget.recorder ?? DeviceRecorder();
  late final VoiceApi _voice = widget.voiceApi ?? VoiceApi(sl<ApiClient>());
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  DraftReply? _last;
  bool _paymentManual =
      false; // the person chose cash / instalments on the card

  /// Cash or instalments is known: the assistant heard it, or it was chosen on the card.
  bool get _paymentSet =>
      _paymentManual || (_last != null && !_last!.missing.contains('payment'));

  /// Everything the text form needs, judged here so the card works even when the assistant is down.
  bool get _textReady =>
      _d.type != null &&
      _d.compound != null &&
      (_d.noRooms || _d.bedroomsSet) &&
      _d.priceValid &&
      _d.detailsValid &&
      _paymentSet &&
      (_d.payment == 'cash' || _d.plan != null);
  bool _busy = false;
  bool _recording = false;
  int _seconds = 0;
  Timer? _tick;

  String get _lang => context.locale.languageCode;
  ListingDraft get _d => widget.draft;

  @override
  void dispose() {
    _tick?.cancel();
    if (widget.recorder == null) _rec.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  void _bot(String text, {List<String> replies = const []}) =>
      _msgs.add(_Msg(false, text, replies: replies));

  Future<void> _send(String raw, {bool voice = false}) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    _d.said.add(text);
    setState(() {
      _msgs.add(_Msg(true, text, voice: voice));
      _busy = true;
      _input.clear();
    });
    _toBottom();
    try {
      final r = await widget.api.parse(text, _d, _lang);
      if (!mounted) return;
      setState(() {
        _d.apply(r.draft, r.compound, r.filled);
        _last = r;
        if (r.unknownCompound) {
          _bot('listing.ai_unknown_compound'.tr());
        } else if (r.complete) {
          _bot('listing.ai_complete'.tr());
        } else if (r.question != null) {
          final n = _filledCount(), t = n + r.missing.length;
          _bot(
            'listing.ai_got'.tr(args: ['$n', '$t', r.question!]),
            replies: r.replies,
          );
        }
        _busy = false;
      });
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _bot(e.message ?? 'listing.ai_failed'.tr());
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bot('listing.ai_failed'.tr());
          _busy = false;
        });
      }
    }
    _toBottom();
  }

  // ── voice ──────────────────────────────────────────────────

  Future<void> _mic() async {
    if (_busy) return;
    if (_recording) return _stopRecording();
    if (!await _rec.requestPermission()) {
      if (mounted) setState(() => _bot('listing.ai_mic_denied'.tr()));
      return;
    }
    try {
      await _rec.start();
    } catch (_) {
      if (mounted) setState(() => _bot('listing.ai_failed'.tr()));
      return;
    }
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= 120) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _tick?.cancel();
    final secs = _seconds;
    setState(() {
      _recording = false;
      _busy = true;
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
      setState(() => _busy = false);
      if (heard.transcript.isEmpty) {
        setState(() => _bot('listing.ai_nospeech'.tr()));
        return;
      }
      await _send(heard.transcript, voice: true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bot('listing.ai_nospeech'.tr());
        });
      }
    }
  }

  // ── media the assistant cannot get from a sentence ──────────

  Future<void> _addPhotos() async {
    try {
      final room = 20 - _d.photos.length;
      if (room <= 0) return;
      final files = await ImagePicker().pickMultiImage(limit: room);
      if (files.isNotEmpty && mounted) {
        setState(() => _d.photos.addAll(files.take(room)));
        _toBottom();
      }
    } catch (_) {}
  }

  Future<void> _pickPlan() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (f != null && mounted) setState(() => _d.floorPlan = f);
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    try {
      final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (f != null && mounted) setState(() => _d.video = f);
    } catch (_) {}
  }

  // ── what the card shows ────────────────────────────────────

  int _filledCount() => _rows().where((r) => r.$2 != null).length;

  /// Label / value rows of the draft; value null = still needed.
  List<(String, String?, CardField)> _rows() {
    final ar = _lang == 'ar';
    final c = _d.compound;
    return [
      (
        'listing.f_type'.tr(),
        _d.type == null
            ? null
            : '${'listing.t_${_d.type}'.tr()} · ${_d.status == 'for_rent' ? 'listing.rent'.tr() : 'listing.sale'.tr()}',
        CardField.type,
      ),
      (
        'listing.f_compound'.tr(),
        c == null
            ? null
            : [c.name(ar), c.sub(ar)].where((s) => s.isNotEmpty).join(' · '),
        CardField.compound,
      ),
      if (!_d.noRooms)
        (
          'listing.f_beds'.tr(),
          _d.bedroomsSet ? '${_d.bedrooms}' : null,
          CardField.beds,
        ),
      (
        'listing.f_size'.tr(),
        _d.sizeValue == null ? null : '${_d.size} m²',
        CardField.size,
      ),
      if (_d.level.trim().isNotEmpty)
        ('listing.f_floor'.tr(), _d.level, CardField.floor),
      if (_d.view != null)
        ('listing.f_view'.tr(), 'listing.v_${_d.view}'.tr(), CardField.view),
      if (_d.delivery != null)
        (
          'listing.f_delivery'.tr(),
          _d.delivery == 'ready' ? 'listing.d_ready'.tr() : _d.delivery,
          CardField.delivery,
        ),
      (
        'listing.f_price'.tr(),
        _d.priceValue == null ? null : 'EGP ${grouped(_d.priceValue!)}',
        CardField.price,
      ),
      (
        'listing.f_payment'.tr(),
        !_paymentSet
            ? null
            : (_d.payment == 'cash'
                  ? 'listing.cash'.tr()
                  : 'listing.plan_text'.tr(args: [_d.down, _d.years])),
        CardField.payment,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final started = _msgs.isNotEmpty;
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
                  onTap: widget.onClose,
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
                        'listing.ai_header'.tr(),
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
                if (!started) ...[
                  Text(
                    'listing.ai_intro'.tr(),
                    style: JV2.display(context, 26),
                  ),
                  const SizedBox(height: 12),
                  Text('listing.ai_intro_sub'.tr(), style: JV2.sub),
                  const SizedBox(height: 18),
                  for (final k in const ['ai_ex1', 'ai_ex2'])
                    GestureDetector(
                      onTap: () => _send('listing.$k'.tr()),
                      child: Container(
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
                    ),
                ],
                for (final (i, m) in _msgs.indexed) ...[
                  _bubble(m),
                  if (i == _firstBotAfterCard) _card(),
                ],
                if (_msgs.isNotEmpty && _firstBotAfterCard < 0) _card(),
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
          _composer(),
        ],
      ),
    );
  }

  // the card sits right after the first user message, then keeps updating in place
  int get _firstBotAfterCard => _msgs.indexWhere((m) => m.user);

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
    final isLast = identical(m, _msgs.last);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.text,
            style: const TextStyle(fontSize: 14, height: 1.5, color: JV2.ink),
          ),
          if (isLast && m.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in m.replies)
                    GestureDetector(
                      onTap: () => _send(r),
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
                          r,
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
    final rows = _rows();
    // the form is complete AND there is at least one photo to publish with
    final textReady = _textReady;
    final ready = textReady && _d.photoCount > 0;
    final filled =
        rows.where((r) => r.$2 != null).length + (_d.photoCount > 0 ? 1 : 0);
    final total = rows.length + 1;
    return Container(
      key: const Key('action-card'),
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ready ? JV2.goldEdge : JV2.line),
        boxShadow: JV2.shadowMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: JV2.navy,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Center(
                    child: SparkIcon(size: 12, color: Color(0xFFE5C48F)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'listing.new_listing'.tr().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                          color: JV2.inkSub,
                        ),
                      ),
                      Text(
                        _d.compound == null
                            ? 'listing.title'.tr()
                            : '${_d.type == null ? '' : 'listing.t_${_d.type}'.tr()} · ${_d.compound!.name(_lang == 'ar')}',
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
                Text(
                  '$filled/$total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: JV2.inkSub,
                  ),
                ),
              ],
            ),
          ),
          for (final r in rows)
            // tap any row to fill it in (or fix it) in the form, so the card works even when the assistant is down
            GestureDetector(
              key: Key('row-${r.$1}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => editCardField(
                context,
                field: r.$3,
                draft: _d,
                api: widget.api,
                ar: _lang == 'ar',
                onChanged: () {
                  if (mounted) setState(() {});
                },
                onPayment: () => _paymentManual = true,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: r.$2 == null ? const Color(0x0FB8893D) : null,
                  border: const Border(top: BorderSide(color: JV2.line)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(
                        r.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: JV2.inkSub),
                      ),
                    ),
                    Expanded(
                      child: r.$2 == null
                          ? Text(
                              'listing.needed'.tr(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: JV2.gold,
                              ),
                            )
                          : Text(
                              r.$2!,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: JV2.ink,
                              ),
                            ),
                    ),
                    if (r.$2 != null)
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: JV2.success,
                      )
                    else
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: JV2.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: JV2.goldEdge),
                        ),
                        child: Text(
                          'listing.add'.tr(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: JV2.navy,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // what a sentence can't carry: photos (needed), floor plan and video (optional)
          _mediaRow(
            key: const Key('media-photos'),
            label: 'listing.f_photos'.tr(),
            have: _d.photoCount > 0,
            valueText: 'listing.n_photos'.tr(args: ['${_d.photoCount}']),
            required: true,
            actionLabel: _d.photoCount > 0
                ? 'listing.add_more'.tr()
                : 'listing.upload'.tr(),
            onTap: _addPhotos,
          ),
          _mediaRow(
            key: const Key('media-plan'),
            label: 'listing.floor_plan'.tr(),
            have: _d.floorPlan != null,
            valueText: 'listing.added'.tr(),
            required: false,
            actionLabel: _d.floorPlan != null
                ? 'listing.change'.tr()
                : 'listing.upload'.tr(),
            onTap: _pickPlan,
          ),
          _mediaRow(
            key: const Key('media-video'),
            label: 'listing.video'.tr(),
            have: _d.video != null,
            valueText: 'listing.added'.tr(),
            required: false,
            actionLabel: _d.video != null
                ? 'listing.change'.tr()
                : 'listing.upload'.tr(),
            onTap: _pickVideo,
          ),
          if (textReady && _d.photoCount == 0)
            Container(
              key: const Key('photos-hint'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: Color(0x0FB8893D),
                border: Border(top: BorderSide(color: JV2.line)),
              ),
              child: Text(
                'listing.add_photos_hint'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: JV2.gold,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: JV2.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: GestureDetector(
                    key: const Key('open-form'),
                    onTap: widget.onOpenForm,
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: JV2.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: JV2.line),
                      ),
                      child: Text(
                        'listing.open_form'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: JV2.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                if (ready) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 14,
                    child: GestureDetector(
                      key: const Key('review-publish'),
                      onTap: widget.onReview,
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
                          'listing.review_publish'.tr(),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A card row for something the person uploads: "Needed" / "Optional" with an Upload button, or what was added.
  Widget _mediaRow({
    required Key key,
    required String label,
    required bool have,
    required String valueText,
    required bool required,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: !have && required ? const Color(0x0FB8893D) : null,
        border: const Border(top: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: JV2.inkSub),
            ),
          ),
          Expanded(
            child: have
                ? Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: JV2.ink,
                    ),
                  )
                : Text(
                    (required ? 'listing.needed' : 'listing.optional').tr(),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: required ? JV2.gold : JV2.inkMute,
                    ),
                  ),
          ),
          if (have)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 8),
              child: Icon(Icons.check_rounded, size: 14, color: JV2.success),
            ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !have && required ? JV2.goldEdge : JV2.line,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!have)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 5),
                      child: Icon(
                        Icons.file_upload_outlined,
                        size: 13,
                        color: JV2.navy,
                      ),
                    ),
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: JV2.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
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
                      alignment: AlignmentDirectional.centerStart,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: JV2.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: JV2.line),
                      ),
                      child: TextField(
                        key: const Key('ai-input'),
                        controller: _input,
                        enabled: !_busy,
                        onSubmitted: _send,
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(fontSize: 14, color: JV2.ink),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'listing.ai_hint'.tr(),
                          hintStyle: const TextStyle(color: JV2.inkMute),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    key: const Key('ai-send'),
                    onTap: () => _send(_input.text),
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
                          colors: _busy
                              ? const [JV2.fillHi, JV2.fillHi]
                              : const [JV2.navyLift, JV2.navy],
                        ),
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
    );
  }
}
