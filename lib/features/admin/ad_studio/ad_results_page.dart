import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import 'ad_export.dart';
import 'ad_finish_page.dart';
import 'ad_flow_widgets.dart';
import 'ad_studio_api.dart';

/// Step 4: three variations in a swipeable row. Pick one, see the facts it quotes, refine it, then finish and publish.
class AdResultsPage extends StatefulWidget {
  final AdStudioApi api;
  final AdDraft draft;
  const AdResultsPage({super.key, required this.api, required this.draft});

  @override
  State<AdResultsPage> createState() => _AdResultsPageState();
}

class _AdResultsPageState extends State<AdResultsPage> {
  late AdDraft _draft = widget.draft;
  int _sel = 0;
  bool _busy = false; // regenerating or refining
  String? _note;
  late final PageController _page = PageController(viewportFraction: 0.8);

  bool get _ar => context.locale.languageCode == 'ar';

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _regenerate() async {
    if (_busy) return;
    setState(() { _busy = true; _note = null; });
    try {
      final d = await widget.api.regenerate(_draft.id);
      if (mounted) setState(() { _draft = d; _sel = 0; });
      if (_page.hasClients) _page.jumpToPage(0);
    } catch (_) {
      if (mounted) setState(() => _note = 'adstudio.failed');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _refine(String action) async {
    if (_busy || _draft.variations.isEmpty) return;
    setState(() { _busy = true; _note = null; });
    try {
      final (d, changed) = await widget.api.refine(_draft.id, _draft.variations[_sel].id, action);
      if (mounted) setState(() { _draft = d; if (!changed) _note = 'adstudio.refine_none'; });
    } catch (_) {
      if (mounted) setState(() => _note = 'adstudio.failed');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _use() {
    final d = _draft;
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdFinishPage(draft: d, variation: d.variations[_sel])));
  }

  Widget _card(int i, double width) {
    final d = _draft, v = d.variations[i];
    final on = _sel == i;
    return GestureDetector(
      key: Key('ad-var-$i'),
      onTap: () => setState(() => _sel = i),
      child: Container(
        width: width,
        margin: const EdgeInsetsDirectional.only(end: 12),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: on ? JV2.navy : Colors.transparent, width: 2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          AdPreview(imageUrl: v.imageUrl, head: v.head(_ar), sub: v.sub(_ar), cta: v.cta(_ar), aspect: d.width / d.height),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 9, 6, 2),
            child: Row(children: [
              Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? JV2.navy : const Color(0x330B2A4A), width: 2)), child: on ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: JV2.navy, shape: BoxShape.circle))) : null),
              const SizedBox(width: 8),
              Text('adstudio.variation_n'.tr(args: ['${i + 1}']), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: JV2.ink)),
              const SizedBox(width: 6),
              Flexible(child: Text('· ${'adstudio.vtone_${v.tone.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '_')}'.tr()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub))),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vs = _draft.variations;
    final v = vs.isEmpty ? null : vs[_sel];
    return AdFlowScaffold(
      title: 'adstudio.pick_variation'.tr(),
      sub: 'adstudio.step_review'.tr(),
      step: 4,
      right: GestureDetector(
        key: const Key('ad-regenerate'),
        onTap: _regenerate,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (_busy) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.8)) else const AdSpark(size: 11),
          const SizedBox(width: 5),
          Text('adstudio.regenerate'.tr(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: JV2.navy)),
        ]),
      ),
      bottom: v == null ? null : AdPrimary(key: const Key('ad-use'), label: 'adstudio.use_variation'.tr(args: ['${_sel + 1}']), onPressed: _busy ? null : _use),
      bodyOverride: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 18, bottom: 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth * 0.8 - 12;
            final h = (w - 12) * _draft.height / _draft.width + 4 + 4 + 4 + 9 + 2 + 22;
            return SizedBox(
              height: h + 8,
              child: PageView.builder(
                controller: _page,
                padEnds: false,
                itemCount: vs.length,
                itemBuilder: (_, i) => Padding(padding: EdgeInsetsDirectional.only(start: i == 0 ? kAdPad : 0), child: _card(i, w)),
              ),
            );
          }),
          if (v != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(kAdPad, 16, kAdPad, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AdFactsUsed(facts: v.facts, ar: _ar),
                if (v.fallback) AdHint('adstudio.fallback_note'.tr()),
                const SizedBox(height: 16),
                AdDownloadBar(
                  key: ValueKey('dl-${v.id}-${v.imageUrl}-${v.headEn}'),
                  hasEn: v.headEn.isNotEmpty || v.subEn.isNotEmpty,
                  hasAr: v.headAr.isNotEmpty || v.subAr.isNotEmpty,
                  fileName: 'jeeran-ad-${_draft.id}-${v.id}',
                  data: (ar) => AdArtworkData(imageUrl: v.imageUrl, head: v.head(ar), sub: v.sub(ar), cta: v.cta(ar), arabic: ar, width: _draft.width, height: _draft.height),
                  all: [
                    for (final x in vs)
                      ('jeeran-ad-${_draft.id}-${x.id}', (ar) => AdArtworkData(imageUrl: x.imageUrl, head: x.head(ar), sub: x.sub(ar), cta: x.cta(ar), arabic: ar, width: _draft.width, height: _draft.height)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final (action, key) in [('shorter', 'adstudio.r_shorter'), ('urgent', 'adstudio.r_urgent'), ('photo', 'adstudio.r_photo')])
                    GestureDetector(
                      key: Key('ad-refine-$action'),
                      onTap: _busy ? null : () => _refine(action),
                      child: Opacity(
                        opacity: _busy ? 0.5 : 1,
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x330B2A4A))),
                          child: Text(key.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: JV2.navy)),
                        ),
                      ),
                    ),
                ]),
                if (_note != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_note!.tr(), key: const Key('ad-note'), style: const TextStyle(fontSize: 12, color: JV2.inkSub))),
              ]),
            ),
        ]),
      ),
    );
  }
}
