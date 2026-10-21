import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/jv2.dart';
import '../../voice/voice_api.dart';
import '../../voice/voice_services.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import 'ad_check_page.dart';
import 'ad_flow_widgets.dart';
import 'ad_studio_api.dart';
import 'dev_picker.dart';
import 'promo_picker.dart';

enum _Dictation { idle, recording, transcribing }

String _id(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '_');

/// Step 1: what the ad should say, who it is for, what it promotes, where it shows and how its image is made.
class AdBriefPage extends StatefulWidget {
  final AdStudioApi? api;
  // test hooks; the real ones open the pickers / microphone
  final Future<List<String>> Function()? pickImages; // local paths
  final Future<List<DevRef>> Function()? loadDevelopers;
  final PromoLoader? loadPromo;
  final VoiceRecorder? recorder;
  final VoiceApi? voiceApi;
  const AdBriefPage({super.key, this.api, this.pickImages, this.loadDevelopers, this.loadPromo, this.recorder, this.voiceApi});

  @override
  State<AdBriefPage> createState() => _AdBriefPageState();
}

class _AdBriefPageState extends State<AdBriefPage> {
  late final AdStudioApi _api = widget.api ?? AdStudioApi();
  final _summary = TextEditingController();
  final _cw = TextEditingController(text: '1080');
  final _ch = TextEditingController(text: '1350');
  final AdBrief _brief = AdBrief();
  DevRef? _dev;
  String _promoKind = 'compound';
  // An app ad picks where it runs by name instead of raw pixels — each choice just sets _brief.size
  // underneath, so the backend and everything downstream (sizing, scoring) is unchanged.
  String _appFormat = 'news'; // banner | news | social — 'news' matches AdBrief's default size ('top')
  String _appPlatform = 'instagram'; // instagram | whatsapp | facebook — only used when _appFormat == 'social'
  static const _appSizeFor = {'banner': 'feed', 'news': 'top', 'instagram': 'post', 'whatsapp': 'story', 'facebook': 'profile'};
  bool _busy = false, _uploading = false;
  String? _error;
  final List<String> _uploaded = [];
  final Map<String, AdImageScore> _scores = {};
  final Set<String> _kept = {};

  // voice note: dictate the summary (same recorder and transcription as the AI chat)
  late final VoiceRecorder _rec = widget.recorder ?? DeviceRecorder();
  late final VoiceApi _voiceApi = widget.voiceApi ?? VoiceApi(sl<ApiClient>());
  static const _maxVoiceSeconds = 120; // what the server accepts
  _Dictation _dictation = _Dictation.idle;
  int _voiceSeconds = 0;
  Timer? _voiceTick;

  bool get _ar => context.locale.languageCode == 'ar';

  bool _used(String url) {
    final s = _scores[url];
    return s == null || s.ok || (!s.bad && _kept.contains(url));
  }

  // An app ad has no compound/property to fall back on for a photo, so — unlike a place ad, where
  // images are optional — it needs at least one usable one before it can go any further.
  bool get _hasUsableImage => _uploaded.any(_used);

  @override
  void dispose() {
    _voiceTick?.cancel();
    if (_dictation == _Dictation.recording) _rec.cancel();
    if (widget.recorder == null) _rec.dispose();
    for (final c in [_summary, _cw, _ch]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── voice ────────────────────────────────────────────────

  void _voiceNotice(String key) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(key.tr())));
  }

  Future<void> _toggleDictation() async {
    if (_dictation == _Dictation.transcribing) return;
    if (_dictation == _Dictation.recording) return _finishDictation();
    if (!await _rec.requestPermission()) return _voiceNotice('voice.denied_sub');
    try {
      await _rec.start();
    } catch (_) {
      return _voiceNotice('voice.failed_sub');
    }
    if (!mounted) return;
    setState(() { _dictation = _Dictation.recording; _voiceSeconds = 0; });
    _voiceTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _voiceSeconds++);
      if (_voiceSeconds >= _maxVoiceSeconds) _finishDictation();
    });
  }

  Future<void> _finishDictation() async {
    if (_dictation != _Dictation.recording) return;
    _voiceTick?.cancel();
    final seconds = _voiceSeconds;
    final lang = context.locale.languageCode;
    setState(() => _dictation = _Dictation.transcribing);
    try {
      final path = await _rec.stop();
      if (path == null || seconds < 1) return _voiceNotice('voice.nospeech_title');
      final heard = await _voiceApi.transcribe(path, seconds: seconds, language: lang);
      if (!mounted) return;
      final text = heard.transcript.trim();
      if (text.isEmpty) return _voiceNotice('voice.nospeech_title');
      final old = _summary.text.trimRight(); // a second note continues the first
      _summary.text = old.isEmpty ? text : '$old $text';
      _summary.selection = TextSelection.collapsed(offset: _summary.text.length);
    } catch (_) {
      _voiceNotice('voice.failed_title');
    } finally {
      if (mounted) setState(() => _dictation = _Dictation.idle);
    }
  }

  String _clock(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ── pickers ──────────────────────────────────────────────

  Future<void> _chooseDev() async {
    final d = await showModalBottomSheet<DevRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JV2.bgDeep,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => DevPickerSheet(load: widget.loadDevelopers ?? loadDevelopers, ar: _ar),
    );
    if (d != null) setState(() { _dev = d; _brief.developerId = d.id; _brief.developerName = d.name(_ar); });
  }

  Future<void> _choosePromo(String kind) async {
    final p = await showModalBottomSheet<PromoPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JV2.bgDeep,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => PromoPickerSheet(initialKind: kind, load: widget.loadPromo ?? loadPromoOptions),
    );
    if (p == null) return;
    setState(() {
      _promoKind = p.kind;
      _promo = p;
      _brief.compoundId = p.kind == 'compound' ? p.id : null;
      _brief.compoundName = p.kind == 'compound' ? p.name : null;
      _brief.propertyId = p.kind == 'unit' ? p.id : null;
      _brief.propertyName = p.kind == 'unit' ? p.name : null;
    });
  }

  PromoPick? _promo;

  void _clearPromo() => setState(() {
    _promo = null;
    _brief.compoundId = _brief.propertyId = null;
    _brief.compoundName = _brief.propertyName = null;
  });

  /// "A place" ↔ "The app": switching to the app clears whatever was linked, since an app ad is never
  /// about a specific compound, developer or unit — see CLAUDE.md's "AI ads" section.
  /// Any image already uploaded is rescored too: "fits the brief" depends on the kind (a logo is off-brief
  /// for a place, exactly right for the app), so a score from before the switch can no longer be trusted.
  void _setKind(String kind) {
    if (_brief.kind == kind) return;
    setState(() {
      _brief.kind = kind;
      if (kind == 'app') {
        _dev = null;
        _brief.developerId = _brief.developerName = null;
        _promo = null;
        _brief.compoundId = _brief.propertyId = null;
        _brief.compoundName = _brief.propertyName = null;
        // the place-mode size grid may have set something the format picker doesn't show (e.g. custom);
        // snap back to whatever format/platform chip is selected so the two stay in sync
        _brief.size = _appSizeFor[_appFormat == 'social' ? _appPlatform : _appFormat]!;
      }
    });
    if (_uploaded.isNotEmpty) { _scores.clear(); _kept.clear(); _score(List.of(_uploaded)); }
  }

  void _pickAppFormat(String fmt) {
    if (_appFormat == fmt) return;
    setState(() {
      _appFormat = fmt;
      _brief.size = fmt == 'social' ? _appSizeFor[_appPlatform]! : _appSizeFor[fmt]!;
    });
    if (_uploaded.isNotEmpty) _rescoreAll(); // the pixels an image needs depend on the size
  }

  void _pickAppPlatform(String p) {
    if (_appPlatform == p) return;
    setState(() {
      _appPlatform = p;
      _brief.size = _appSizeFor[p]!;
    });
    if (_uploaded.isNotEmpty) _rescoreAll();
  }

  Future<void> _addImages() async {
    final paths = await (widget.pickImages ?? () async => [for (final x in await ImagePicker().pickMultiImage(maxWidth: 2400, imageQuality: 88)) x.path])();
    if (paths.isEmpty || !mounted) return;
    setState(() { _uploading = true; _error = null; });
    final added = <String>[];
    try {
      for (final p in paths.take(10 - _uploaded.length)) {
        final url = await _api.upload(p);
        _uploaded.add(url);
        added.add(url);
      }
    } catch (_) {
      _error = 'adstudio.failed';
    }
    await _score(added);
    if (mounted) setState(() => _uploading = false);
  }

  /// Scores images for size, sharpness and fit to the brief. If scoring fails they are simply treated as fine.
  Future<void> _score(List<String> urls) async {
    if (urls.isEmpty) return;
    _brief.summary = _summary.text;
    try {
      for (final s in await _api.scoreImages(urls, brief: _brief)) {
        _scores[s.url] = s;
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _rescoreAll() { _scores.clear(); _score(List.of(_uploaded)); }

  Future<void> _continue() async {
    _brief.summary = _summary.text;
    if (_brief.summary.trim().isEmpty) return;
    _brief.images = [for (final u in _uploaded) if (_used(u)) u];
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _api.brief(_brief);
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.push(context, MaterialPageRoute(builder: (_) => AdCheckPage(api: _api, brief: _brief, result: result)));
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'adstudio.failed'; });
    }
  }

  // ── pieces ───────────────────────────────────────────────

  static const _line = JV2.line;
  static const _shadow = [BoxShadow(color: Color(0x0D0B2A4A), blurRadius: 2, offset: Offset(0, 1))];

  Widget _removeBtn(VoidCallback onTap, {Key? key}) => GestureDetector(
    key: key,
    onTap: onTap,
    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: JV2.fillFaint, borderRadius: BorderRadius.circular(10), border: Border.all(color: _line)), child: const Icon(Icons.close_rounded, size: 13, color: JV2.ink)),
  );

  Widget _summaryField() {
    final listening = _dictation == _Dictation.recording;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: listening ? JV2.goldEdge : _line),
        boxShadow: listening ? const [BoxShadow(color: Color(0x1AB8893D), spreadRadius: 3)] : _shadow,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            key: const Key('ad-summary'),
            controller: _summary,
            minLines: 4,
            maxLines: 7,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14, height: 1.5, color: JV2.ink),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
              hintText: listening ? 'adstudio.dictating'.tr(args: [_clock(_voiceSeconds)]) : 'adstudio.summary_hint'.tr(),
              hintStyle: const TextStyle(fontSize: 14, height: 1.5, color: JV2.inkMute),
              hintMaxLines: 5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          key: const Key('ad-mic'),
          onTap: _toggleDictation,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: listening ? null : JV2.fillFaint,
              gradient: listening ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE5C48F), JV2.goldHi]) : null,
            ),
            child: switch (_dictation) {
              _Dictation.idle => const Icon(Icons.mic_none_rounded, size: 20, color: JV2.navy),
              _Dictation.recording => Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)))),
              _Dictation.transcribing => const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2.2)),
            },
          ),
        ),
      ]),
    );
  }

  Widget _developer() {
    final d = _dev;
    if (d == null) {
      return AdDashed(
        key: const Key('ad-dev'),
        height: 54,
        onTap: _chooseDev,
        child: Text('adstudio.choose_dev'.tr(), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: JV2.navy)),
      );
    }
    return Container(
      key: const Key('ad-dev'),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line), boxShadow: _shadow),
      child: Row(children: [
        AdLogoTile(url: d.logo, initials: d.initials),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name(_ar), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: JV2.ink)),
            const SizedBox(height: 2),
            Text('adstudio.dev_counts'.tr(args: ['${d.compounds}', '${d.units}']), style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
          ]),
        ),
        _removeBtn(() => setState(() { _dev = null; _brief.developerId = null; _brief.developerName = null; }), key: const Key('ad-dev-remove')),
      ]),
    );
  }

  Widget _promoField() {
    final p = _promo;
    if (p == null) {
      return AdDashed(key: const Key('ad-promo'), height: 54, onTap: () => _choosePromo(_promoKind), child: Text('adstudio.pick_promo'.tr(), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: JV2.navy)));
    }
    return Container(
      key: const Key('ad-promo'),
      decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line), boxShadow: _shadow),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: JV2.fillFaint, border: Border(bottom: BorderSide(color: _line))),
          child: Row(children: [
            for (final (k, t) in [('compound', 'adstudio.k_compound'), ('unit', 'adstudio.k_unit')])
              Expanded(
                child: GestureDetector(
                  key: Key('ad-promo-$k'),
                  onTap: () { if (p.kind != k) _choosePromo(k); },
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(right: k == 'compound' ? 4 : 0),
                    decoration: BoxDecoration(color: p.kind == k ? JV2.surface : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: p.kind == k ? _shadow : null),
                    child: Text(t.tr(), style: TextStyle(fontSize: 12.5, fontWeight: p.kind == k ? FontWeight.w600 : FontWeight.w500, color: p.kind == k ? JV2.ink : JV2.inkSub)),
                  ),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(11),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x4D1A4A80), Color(0x42B8893D)]))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: JV2.ink)),
                if (p.sub.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(p.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub))),
              ]),
            ),
            _removeBtn(_clearPromo, key: const Key('ad-promo-remove')),
          ]),
        ),
      ]),
    );
  }

  Widget _thumb(int i) {
    final url = _uploaded[i];
    final sc = _scores[url];
    final warn = sc != null && sc.status == 'warn';
    final bad = sc != null && sc.bad;
    final kept = _kept.contains(url);
    final good = sc != null && (sc.ok || (warn && kept));
    final Color fg = bad ? JV2.danger : (good ? JV2.success : const Color(0xFF8A5F12));
    final Color bg = bad ? const Color(0xFFFDECEC) : (good ? const Color(0xF0FFFFFF) : const Color(0xFFFFF6E6));
    final label = sc == null ? '' : (warn && kept ? 'adstudio.score_kept'.tr() : 'adstudio.score_${sc.label}'.tr());
    return GestureDetector(
      key: Key('ad-img-$i'),
      onTap: warn ? () => setState(() => kept ? _kept.remove(url) : _kept.add(url)) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bad ? const Color(0x80C23B3B) : (sc == null || sc.ok ? _line : JV2.goldEdge), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: sc == null || sc.ok ? 1 : 0.85,
          child: Stack(fit: StackFit.expand, children: [
            Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: JV2.fillHi)),
            PositionedDirectional(top: 4, end: 4, child: GestureDetector(key: Key('ad-img-x-$i'), onTap: () => setState(() { _uploaded.removeAt(i); _scores.remove(url); _kept.remove(url); }), child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: Color(0x8C0E1726), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 9, color: Colors.white)))),
            if (sc != null)
              PositionedDirectional(
                start: 4,
                end: 4,
                bottom: 4,
                child: Container(
                  key: Key('ad-score-$i'),
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (sc.ok) ...[const Icon(Icons.check_rounded, size: 9, color: JV2.success), const SizedBox(width: 3)],
                    Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: fg))),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _modeCard(String id, String title, String desc) {
    final on = _brief.imageMode == id;
    return GestureDetector(
      key: Key('ad-mode-$id'),
      onTap: () => setState(() => _brief.imageMode = id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(color: on ? const Color(0x0D0B2A4A) : JV2.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: on ? JV2.navy : _line, width: 1.5)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? JV2.navy : const Color(0x330B2A4A), width: 2)),
            child: on ? Center(child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: JV2.navy, shape: BoxShape.circle))) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: JV2.ink))), if (id == 'generate') ...[const SizedBox(width: 6), const AdSpark(size: 11)]]),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(fontSize: 12, height: 1.45, color: JV2.inkSub)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sizeTile((String, String, int, int) s) {
    final (id, key, w, h) = s;
    final on = _brief.size == id;
    final custom = id == 'custom';
    final cw = int.tryParse(_cw.text) ?? 1, ch = int.tryParse(_ch.text) ?? 1;
    final r = custom ? cw / (ch == 0 ? 1 : ch) : w / h;
    final bw = r >= 1 ? 40.0 : 40 * r, bh = r >= 1 ? 40 / r : 40.0;
    final box = Color(on ? 0xFF0B2A4A : 0x120B2A4A);
    return GestureDetector(
      key: Key('ad-size-$id'),
      onTap: () {
        if (_brief.size == id) return;
        setState(() => _brief.size = id);
        if (_uploaded.isNotEmpty) _rescoreAll(); // the pixels an image needs depend on the size
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 9),
        decoration: BoxDecoration(color: on ? const Color(0x0D0B2A4A) : JV2.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: on ? JV2.navy : _line, width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: custom
                  ? AdDashed(width: bw.clamp(10, 40).toDouble(), height: bh.clamp(10, 40).toDouble(), radius: 4, color: on ? const Color(0xFF0B2A4A) : const Color(0x330B2A4A), child: const SizedBox())
                  : Container(width: bw.clamp(10, 40).toDouble(), height: bh.clamp(10, 40).toDouble(), decoration: BoxDecoration(color: box, borderRadius: BorderRadius.circular(4))),
            ),
          ),
          const SizedBox(height: 7),
          Text(key.tr(), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: JV2.ink, height: 1.2)),
          const SizedBox(height: 7),
          Text(custom ? 'adstudio.your_size'.tr() : '$w×$h', style: const TextStyle(fontSize: 10.5, color: JV2.inkMute, fontFeatures: [FontFeature.tabularFigures()])),
        ]),
      ),
    );
  }

  Widget _sizeField(String label, TextEditingController c, Key k) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: JV2.ink))),
      Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: _line), boxShadow: _shadow),
        child: Row(children: [
          Expanded(
            child: TextField(
              key: k,
              controller: c,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              onChanged: (v) => setState(() {
                final n = int.tryParse(v) ?? 0;
                if (c == _cw) { _brief.customWidth = n; } else { _brief.customHeight = n; }
              }),
              style: const TextStyle(fontSize: 15, color: JV2.ink),
              decoration: const InputDecoration(isCollapsed: true, filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
            ),
          ),
          const Text('px', style: TextStyle(fontSize: 12, color: JV2.inkMute)),
        ]),
      ),
    ]),
  );

  String _sizeHint() {
    if (_brief.size == 'custom') {
      final w = _brief.customWidth, h = _brief.customHeight;
      return 'adstudio.custom_hint'.tr(args: [(w > 0 && h > 0) ? (w / h).toStringAsFixed(2) : '—']);
    }
    return 'adstudio.size_desc_${_brief.size}'.tr();
  }

  String _imagesHint() {
    final bad = _uploaded.where((u) => _scores[u]?.bad == true).length;
    final head = bad > 0 ? '${'adstudio.images_bad'.tr(args: ['$bad'])} ' : '';
    return '$head${(_brief.isApp ? 'adstudio.images_note_app' : 'adstudio.images_note').tr()}';
  }

  @override
  Widget build(BuildContext context) {
    final needsImage = _brief.isApp && !_hasUsableImage;
    final can = _summary.text.trim().isNotEmpty && !needsImage && !_busy;
    final dev = _dev?.name(_ar);
    return AdFlowScaffold(
      title: 'adstudio.new_ad'.tr(),
      sub: 'adstudio.step_brief'.tr(),
      step: 1,
      gap: 24,
      padding: const EdgeInsets.fromLTRB(kAdPad, 20, kAdPad, 26),
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!.tr(), key: const Key('ad-error'), style: const TextStyle(fontSize: 12, color: JV2.danger))),
        if (_summary.text.trim().isEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('adstudio.write_summary'.tr(), style: const TextStyle(fontSize: 11.5, color: JV2.inkSub))),
        if (_summary.text.trim().isNotEmpty && needsImage) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('adstudio.need_app_image'.tr(), key: const Key('ad-need-image'), style: const TextStyle(fontSize: 11.5, color: JV2.inkSub))),
        AdPrimary(key: const Key('ad-continue'), label: 'adstudio.continue'.tr(), spark: true, onPressed: can ? _continue : null, busy: _busy),
      ]),
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdLabel('adstudio.summary'.tr(), sub: 'adstudio.required'.tr()),
          _summaryField(),
          AdHint('adstudio.summary_note'.tr()),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdLabel('adstudio.what_for'.tr()),
          Row(children: [
            Expanded(child: AdChoice(key: const Key('ad-kind-inventory'), on: !_brief.isApp, label: 'adstudio.kind_place'.tr(), onTap: () => _setKind('inventory'))),
            const SizedBox(width: 8),
            Expanded(child: AdChoice(key: const Key('ad-kind-app'), on: _brief.isApp, label: 'adstudio.kind_app'.tr(), onTap: () => _setKind('app'))),
          ]),
          AdHint((_brief.isApp ? 'adstudio.kind_hint_app' : 'adstudio.kind_hint_place').tr()),
        ]),
        if (!_brief.isApp) ...[
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdLabel('adstudio.developer'.tr(), sub: 'adstudio.optional'.tr()),
            _developer(),
            AdHint(dev != null ? 'adstudio.dev_hint'.tr(args: [dev]) : 'adstudio.dev_hint_none'.tr()),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdLabel('adstudio.promoting'.tr(), sub: 'adstudio.optional'.tr()),
            _promoField(),
            AdHint(_promo != null ? 'adstudio.promo_hint'.tr() : 'adstudio.promo_hint_none'.tr()),
          ]),
        ],
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdLabel('adstudio.your_images'.tr(), sub: 'adstudio.images_count'.tr(args: ['${_uploaded.length}'])),
          if (_uploaded.isNotEmpty || _uploading)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [for (var i = 0; i < _uploaded.length; i++) _thumb(i), if (_uploading) const Center(child: CircularProgressIndicator(strokeWidth: 2))],
            ),
          if (_uploaded.isNotEmpty) AdHint.markup(_imagesHint()),
          if (_uploaded.isEmpty) AdHint((_brief.isApp ? 'adstudio.images_none_app' : 'adstudio.images_none').tr()),
          const SizedBox(height: 8),
          AdDashed(
            key: const Key('ad-add-images'),
            height: 44,
            radius: 13,
            onTap: _uploading || _uploaded.length >= 10 ? null : _addImages,
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.photo_camera_outlined, size: 15, color: JV2.navy), const SizedBox(width: 7), Text('adstudio.upload_images'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: JV2.navy))]),
          ),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdLabel('adstudio.ai_use'.tr()),
          _modeCard('original', 'adstudio.use_original'.tr(), 'adstudio.use_original_sub'.tr()),
          const SizedBox(height: 8),
          _modeCard('generate', 'adstudio.use_generate'.tr(), 'adstudio.use_generate_sub'.tr()),
        ]),
        if (_brief.isApp)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdLabel('adstudio.where_runs'.tr()),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in const ['banner', 'news', 'social'])
                AdChoice(key: Key('ad-fmt-$f'), on: _appFormat == f, label: 'adstudio.fmt_$f'.tr(), onTap: () => _pickAppFormat(f)),
            ]),
            if (_appFormat == 'social') ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in const ['instagram', 'whatsapp', 'facebook'])
                  AdChoice(key: Key('ad-plat-$p'), on: _appPlatform == p, label: 'adstudio.plat_$p'.tr(), onTap: () => _pickAppPlatform(p)),
              ]),
            ],
            AdHint(_sizeHint()),
          ])
        else
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdLabel('adstudio.image_size'.tr(), sub: 'adstudio.image_size_sub'.tr()),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 132),
              children: [for (final s in adSizes) _sizeTile(s)],
            ),
            if (_brief.size == 'custom') Padding(padding: const EdgeInsets.only(top: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [_sizeField('adstudio.width'.tr(), _cw, const Key('ad-width')), const Padding(padding: EdgeInsets.fromLTRB(8, 0, 8, 15), child: Text('×', style: TextStyle(fontSize: 14, color: JV2.inkMute))), _sizeField('adstudio.height'.tr(), _ch, const Key('ad-height'))])),
            AdHint(_sizeHint()),
          ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdLabel('adstudio.tone'.tr()),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final v in const ['Premium', 'Offer-led', 'Family', 'Launch hype']) AdChoice(key: Key('ad-tone-$v'), on: _brief.tone == v, label: 'adstudio.tone_${_id(v)}'.tr(), onTap: () => setState(() => _brief.tone = v))]),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdLabel('adstudio.language'.tr()),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final v in const ['English', 'Arabic', 'English + Arabic']) AdChoice(key: Key('ad-lang-$v'), on: _brief.language == v, label: 'adstudio.lang_${_id(v)}'.tr(), onTap: () => setState(() => _brief.language = v))]),
        ]),
      ],
    );
  }
}
