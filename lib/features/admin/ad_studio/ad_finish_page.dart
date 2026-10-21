import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import 'ad_export.dart';
import 'ad_flow_widgets.dart';
import 'ad_studio_api.dart';

/// The last step: your AI ad. Fine-tune the words (the picture follows), then download it or share it.
class AdFinishPage extends StatefulWidget {
  final AdDraft draft;
  final AdVariation variation;
  const AdFinishPage({super.key, required this.draft, required this.variation});

  @override
  State<AdFinishPage> createState() => _AdFinishPageState();
}

class _AdFinishPageState extends State<AdFinishPage> {
  late final _headEn = TextEditingController(text: widget.variation.headEn);
  late final _headAr = TextEditingController(text: widget.variation.headAr);
  late final _subEn = TextEditingController(text: widget.variation.subEn);
  late final _subAr = TextEditingController(text: widget.variation.subAr);
  late final _ctaEn = TextEditingController(text: widget.variation.ctaEn);
  late final _ctaAr = TextEditingController(text: widget.variation.ctaAr);
  final Set<String> _edited = {}; // fields the admin changed: they lose the "AI wrote this" mark

  bool get _ar => context.locale.languageCode == 'ar';
  AdDraft get _d => widget.draft;
  AdVariation get _v => widget.variation;
  bool get _hasEn => _v.headEn.isNotEmpty || _v.subEn.isNotEmpty;
  bool get _hasAr => _v.headAr.isNotEmpty || _v.subAr.isNotEmpty;

  @override
  void dispose() {
    for (final c in [_headEn, _headAr, _subEn, _subAr, _ctaEn, _ctaAr]) {
      c.dispose();
    }
    super.dispose();
  }

  String _pick(bool ar, TextEditingController en, TextEditingController arabic) =>
      ar ? (arabic.text.isNotEmpty ? arabic.text : en.text) : (en.text.isNotEmpty ? en.text : arabic.text);

  AdArtworkData _artwork(bool ar) => AdArtworkData(
    imageUrl: _v.imageUrl,
    head: _pick(ar, _headEn, _headAr),
    sub: _pick(ar, _subEn, _subAr),
    cta: _pick(ar, _ctaEn, _ctaAr),
    arabic: ar,
    width: _d.width,
    height: _d.height,
  );

  Widget _field(String label, TextEditingController c, String key, {bool rtl = false}) {
    final ai = !_edited.contains(key) && c.text.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(children: [
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: JV2.ink))),
          const Spacer(),
          if (ai) const _AiTag(),
        ]),
      ),
      Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: ai ? JV2.goldEdge : JV2.line)),
        child: TextField(
          key: Key('ad-f-$key'),
          controller: c,
          textDirection: rtl ? ui.TextDirection.rtl : null,
          minLines: 1,
          maxLines: 3,
          onChanged: (_) => setState(() => _edited.add(key)),
          style: const TextStyle(fontSize: 14, color: JV2.ink),
          decoration: const InputDecoration(isCollapsed: true, filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final a = _artwork(_ar);
    final both = _hasEn && _hasAr;
    return AdFlowScaffold(
      title: 'adstudio.your_ai_ad'.tr(),
      sub: 'adstudio.px_size'.tr(args: ['${_d.width}', '${_d.height}']),
      gap: 20,
      padding: const EdgeInsets.fromLTRB(kAdPad, 18, kAdPad, 26),
      bottom: AdDownloadBar(
        hasEn: _headEn.text.isNotEmpty || _subEn.text.isNotEmpty,
        hasAr: _headAr.text.isNotEmpty || _subAr.text.isNotEmpty,
        fileName: 'jeeran-ai-ad-${_d.id}-${_v.id}',
        data: _artwork,
      ),
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdLabel('adstudio.preview'.tr(), sub: 'adstudio.preview_sub2'.tr()),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _d.height > _d.width ? 260 : double.infinity),
              child: AdPreview(imageUrl: a.imageUrl, head: a.head, sub: a.sub, cta: a.cta, aspect: _d.width / _d.height),
            ),
          ),
        ]),
        if (_hasEn) _field('adstudio.headline'.tr() + (both ? ' · EN' : ''), _headEn, 'head_en'),
        if (_hasAr) _field('adstudio.headline'.tr() + (both ? ' · AR' : ''), _headAr, 'head_ar', rtl: true),
        if (_hasEn) _field('adstudio.subline'.tr() + (both ? ' · EN' : ''), _subEn, 'sub_en'),
        if (_hasAr) _field('adstudio.subline'.tr() + (both ? ' · AR' : ''), _subAr, 'sub_ar', rtl: true),
        if (_hasEn) _field('adstudio.button'.tr() + (both ? ' · EN' : ''), _ctaEn, 'cta_en'),
        if (_hasAr) _field('adstudio.button'.tr() + (both ? ' · AR' : ''), _ctaAr, 'cta_ar', rtl: true),
        Container(
          key: const Key('ad-checks'),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(color: const Color(0x0F137A55), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x38137A55))),
          child: Column(children: [
            for (final t in [_v.facts.isNotEmpty ? 'adstudio.chk_numbers'.tr() : 'adstudio.chk_no_numbers'.tr(), if (_v.aiImage) 'adstudio.chk_image_ai'.tr() else 'adstudio.chk_image_orig'.tr()])
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.check_rounded, size: 14, color: JV2.success), const SizedBox(width: 9), Expanded(child: Text(t, style: const TextStyle(fontSize: 12.5, color: JV2.ink)))])),
          ]),
        ),
      ],
    );
  }
}

/// The design's "Jeeran" mark on a field the AI wrote, until the admin edits it.
class _AiTag extends StatelessWidget {
  const _AiTag();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: JV2.goldFilm, borderRadius: BorderRadius.circular(999), border: Border.all(color: JV2.goldEdge)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [AdSpark(size: 9), SizedBox(width: 4), Text('Jeeran', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: JV2.gold, letterSpacing: 0.2))]),
  );
}
