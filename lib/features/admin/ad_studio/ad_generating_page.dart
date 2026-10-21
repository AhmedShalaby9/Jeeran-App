import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import 'ad_flow_widgets.dart';
import 'ad_results_page.dart';
import 'ad_studio_api.dart';

/// Step 3: the AI writes three variations and builds their images (usually under a minute). It opens the result on its own.
class AdGeneratingPage extends StatefulWidget {
  final AdStudioApi api;
  final AdBrief brief;
  final AdUnderstood understood;
  final List<String> approved;
  final String subject; // "Pulling Marassi prices…"
  const AdGeneratingPage({super.key, required this.api, required this.brief, required this.understood, required this.approved, this.subject = ''});

  @override
  State<AdGeneratingPage> createState() => _AdGeneratingPageState();
}

class _AdGeneratingPageState extends State<AdGeneratingPage> with SingleTickerProviderStateMixin {
  int _stage = 0;
  Timer? _tick;
  bool _failed = false;
  late final AnimationController _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted && _stage < 3) setState(() => _stage++);
    });
    _run();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() { _failed = false; _stage = 0; });
    try {
      final draft = await widget.api.generate(widget.brief, understood: widget.understood, approved: widget.approved);
      if (!mounted) return;
      _tick?.cancel();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdResultsPage(api: widget.api, draft: draft)));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Widget _skeleton() {
    final sub = widget.subject.isEmpty ? '' : widget.subject;
    return AspectRatio(
      aspectRatio: 16 / 11,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: JV2.line), gradient: const LinearGradient(begin: Alignment(-0.4, -1), end: Alignment(0.4, 1), colors: [Color(0x2E1A4A80), Color(0x29B8893D)])),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          AnimatedBuilder(
            animation: _sweep,
            builder: (_, _) => FractionallySizedBox(
              alignment: Alignment(-1.2 + 3.6 * _sweep.value, 0),
              widthFactor: 0.35,
              heightFactor: 1,
              child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x00FFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)]))),
            ),
          ),
          PositionedDirectional(
            start: 14,
            end: 14,
            bottom: 14,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              FractionallySizedBox(widthFactor: .7, child: Container(height: 14, decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(5)))),
              const SizedBox(height: 7),
              FractionallySizedBox(widthFactor: .45, child: Container(height: 9, decoration: BoxDecoration(color: const Color(0x8CFFFFFF), borderRadius: BorderRadius.circular(4)))),
            ]),
          ),
          if (sub.isEmpty) const SizedBox.shrink(),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'adstudio.g_1'.tr(),
      widget.subject.isEmpty ? 'adstudio.g_2_plain'.tr() : 'adstudio.g_2'.tr(args: [widget.subject]),
      'adstudio.g_3'.tr(),
      'adstudio.g_4'.tr(),
    ];
    return AdFlowScaffold(
      title: 'adstudio.new_ad'.tr(),
      sub: 'adstudio.step_generating'.tr(),
      step: 3,
      gap: 18,
      padding: const EdgeInsets.fromLTRB(kAdPad, 22, kAdPad, 30),
      children: _failed
          ? [
              const SizedBox(height: 30),
              Center(child: Text('adstudio.gen_failed'.tr(), key: const Key('ad-gen-failed'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: JV2.inkSub))),
              Center(child: FilledButton(key: const Key('ad-gen-retry'), onPressed: _run, child: Text('adstudio.retry'.tr()))),
            ]
          : [
              _skeleton(),
              Row(children: [for (var i = 0; i < 3; i++) Expanded(child: Container(height: 5, margin: EdgeInsetsDirectional.only(end: i < 2 ? 8 : 0), decoration: BoxDecoration(color: i < _stage ? JV2.navy : JV2.track, borderRadius: BorderRadius.circular(3))))]),
              Column(children: [
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 12 : 0),
                    child: Opacity(
                      opacity: i > _stage ? 0.45 : 1,
                      child: Row(children: [
                        _StepDot(done: i < _stage, now: i == _stage),
                        const SizedBox(width: 11),
                        Expanded(child: Text(steps[i], style: TextStyle(fontSize: 13.5, fontWeight: i == _stage ? FontWeight.w600 : FontWeight.w400, color: JV2.ink))),
                      ]),
                    ),
                  ),
              ]),
              Text('adstudio.g_note'.tr(), style: const TextStyle(fontSize: 12, height: 1.5, color: JV2.inkSub)),
            ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool done, now;
  const _StepDot({required this.done, required this.now});

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(width: 22, height: 22, decoration: const BoxDecoration(color: JV2.success, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 12, color: Colors.white));
    }
    if (now) {
      return const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: JV2.goldHi));
    }
    return Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x330B2A4A), width: 2)));
  }
}
