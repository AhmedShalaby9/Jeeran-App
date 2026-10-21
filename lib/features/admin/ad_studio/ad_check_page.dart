import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import 'ad_flow_widgets.dart';
import 'ad_generating_page.dart';
import 'ad_studio_api.dart';

/// Step 2: what the AI understood (fix it here, it is cheaper than regenerating) and which facts the ad may quote.
class AdCheckPage extends StatefulWidget {
  final AdStudioApi api;
  final AdBrief brief;
  final AdBriefResult result;
  const AdCheckPage({super.key, required this.api, required this.brief, required this.result});

  @override
  State<AdCheckPage> createState() => _AdCheckPageState();
}

class _AdCheckPageState extends State<AdCheckPage> {
  late final AdUnderstood _u = AdUnderstood(audience: widget.result.understood.audience, angle: widget.result.understood.angle, feel: widget.result.understood.feel, mustShow: widget.result.understood.mustShow);
  late final List<bool> _on = [for (final f in widget.result.facts) f.defaultOn];

  bool get _ar => context.locale.languageCode == 'ar';

  Future<void> _edit(String title, String? current, void Function(String?) set) async {
    final c = TextEditingController(text: current ?? '');
    final v = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(key: const Key('ad-understood-field'), controller: c, autofocus: true, maxLength: 80, decoration: const InputDecoration(counterText: '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text('adstudio.cancel'.tr())),
          TextButton(key: const Key('ad-understood-ok'), onPressed: () => Navigator.pop(d, c.text), child: Text('adstudio.ok'.tr())),
        ],
      ),
    );
    if (v != null) setState(() => set(v.trim().isEmpty ? null : v.trim()));
  }

  void _generate() {
    final approved = [for (var i = 0; i < _on.length; i++) if (_on[i]) widget.result.facts[i].key];
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdGeneratingPage(api: widget.api, brief: widget.brief, understood: _u, approved: approved, subject: _ar ? widget.result.subjectAr : widget.result.subjectEn)));
  }

  @override
  Widget build(BuildContext context) {
    final facts = widget.result.facts;
    final n = _on.where((x) => x).length;
    final rows = <(String, String?, void Function(String?))>[
      ('adstudio.u_audience'.tr(), _u.audience, (v) => _u.audience = v),
      ('adstudio.u_angle'.tr(), _u.angle, (v) => _u.angle = v),
      ('adstudio.u_feel'.tr(), _u.feel, (v) => _u.feel = v),
      ('adstudio.u_must'.tr(), _u.mustShow, (v) => _u.mustShow = v),
    ];
    return AdFlowScaffold(
      title: 'adstudio.new_ad'.tr(),
      sub: 'adstudio.step_check'.tr(),
      step: 2,
      gap: 22,
      bottom: AdPrimary(key: const Key('ad-generate'), label: 'adstudio.looks_right'.tr(), spark: true, onPressed: _generate),
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [const AdSpark(size: 13), const SizedBox(width: 8), Text('adstudio.understood'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: JV2.ink))]),
          ),
          AdCard(children: [
            for (var i = 0; i < rows.length; i++)
              InkWell(
                key: Key('ad-u-$i'),
                onTap: () => _edit(rows[i].$1, rows[i].$2, rows[i].$3),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border(top: i == 0 ? BorderSide.none : const BorderSide(color: JV2.line))),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(children: [
                    SizedBox(width: 82, child: Text(rows[i].$1, style: const TextStyle(fontSize: 12.5, color: JV2.inkSub))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(rows[i].$2 ?? '—', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: rows[i].$2 == null ? JV2.inkMute : JV2.ink))),
                    const Icon(Icons.edit_outlined, size: 14, color: JV2.navy),
                  ]),
                ),
              ),
          ]),
          AdHint('adstudio.understood_note'.tr()),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('adstudio.facts_title'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: JV2.ink)),
              const Spacer(),
              Text('adstudio.n_of'.tr(args: ['$n', '${facts.length}']), style: const TextStyle(fontSize: 11.5, color: JV2.inkMute)),
            ]),
          ),
          if (facts.isEmpty)
            AdCard(children: [Padding(padding: const EdgeInsets.all(16), child: Text('adstudio.no_facts'.tr(), key: const Key('ad-no-facts'), style: const TextStyle(fontSize: 13, color: JV2.inkSub)))])
          else
            AdCard(children: [
              for (var i = 0; i < facts.length; i++)
                Container(
                  decoration: BoxDecoration(border: Border(top: i == 0 ? BorderSide.none : const BorderSide(color: JV2.line))),
                  child: AdFactCheckRow(key: Key('ad-fact-${facts[i].key}'), fact: facts[i], ar: _ar, on: _on[i], onTap: () => setState(() => _on[i] = !_on[i])),
                ),
            ]),
          AdHint('adstudio.facts_note'.tr()),
        ]),
      ],
    );
  }
}
