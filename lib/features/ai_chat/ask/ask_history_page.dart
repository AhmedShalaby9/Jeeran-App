import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
import 'ask_api.dart';
import 'ask_widgets.dart';

/// What the history screen hands back: a chat to open and/or the fact that the open one was deleted.
class AskHistoryResult {
  final AskSessionRow? open;
  final bool deletedCurrent;
  const AskHistoryResult({this.open, this.deletedCurrent = false});
}

class AskHistoryPage extends StatefulWidget {
  final AskApi api;
  final int? currentSessionId;
  const AskHistoryPage({super.key, required this.api, this.currentSessionId});

  @override
  State<AskHistoryPage> createState() => _AskHistoryPageState();
}

class _AskHistoryPageState extends State<AskHistoryPage> {
  List<AskSessionRow>? _rows;
  bool _failed = false;
  bool _deletedCurrent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final rows = await widget.api.sessions();
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _delete(AskSessionRow r) async {
    final before = _rows!;
    setState(() => _rows = before.where((x) => x.id != r.id).toList());
    if (r.id == widget.currentSessionId) _deletedCurrent = true;
    try {
      await widget.api.delete(r.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rows = before);
      if (r.id == widget.currentSessionId) _deletedCurrent = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('concierge.delete_failed'.tr())));
    }
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'notif.ago_now'.tr();
    if (d.inMinutes < 60) return 'notif.ago_m'.tr(args: ['${d.inMinutes}']);
    if (d.inHours < 24) return 'notif.ago_h'.tr(args: ['${d.inHours}']);
    if (d.inDays < 7) return 'notif.ago_d'.tr(args: ['${d.inDays}']);
    return 'notif.ago_w'.tr(args: ['${d.inDays ~/ 7}']);
  }

  String _meta(AskSessionRow r) {
    final what = AskAssistantMsg.sourcesOf(
      AskRefs(
        properties: List.filled(r.listings, const {}),
        projects: List.filled(r.compounds, const {}),
        news: List.filled(r.news, const {}),
      ),
    );
    return [
      what.isEmpty ? 'concierge.meta_account'.tr() : what,
      _ago(r.updatedAt),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop)
          Navigator.pop(
            context,
            _deletedCurrent
                ? const AskHistoryResult(deletedCurrent: true)
                : null,
          );
      },
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                kAskPad,
                MediaQuery.of(context).padding.top + 8,
                kAskPad,
                14,
              ),
              decoration: const BoxDecoration(
                color: Color(0xE6FAFBFD),
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
                      child: Icon(
                        isRtl(context)
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        size: 22,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'concierge.history_title'.tr(),
                      style: JV2.display(context, 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('concierge.load_failed'.tr(), style: JV2.display(context, 20)),
            const SizedBox(height: 14),
            JV2PrimaryButton(
              width: 150,
              height: 44,
              onPressed: _load,
              child: Text('concierge.retry'.tr()),
            ),
          ],
        ),
      );
    }
    final rows = _rows;
    if (rows == null)
      return const Center(child: CircularProgressIndicator(color: JV2.navy));
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'concierge.history_empty_title'.tr(),
                style: JV2.display(context, 21),
              ),
              const SizedBox(height: 10),
              Text(
                'concierge.history_empty_sub'.tr(),
                textAlign: TextAlign.center,
                style: JV2.sub.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(kAskPad, 14, kAskPad, 26),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = rows[i];
        return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 13, 12, 13),
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: JV2.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(
                    context,
                    AskHistoryResult(open: r, deletedCurrent: _deletedCurrent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: JV2.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _meta(r),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: JV2.inkSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 11),
              GestureDetector(
                onTap: () => _delete(r),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: JV2.fillFaint,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: JV2.line),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: JV2.inkSub,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
