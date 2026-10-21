import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/jv2.dart';
import 'ad_brief_page.dart';
import 'ad_flow_widgets.dart';
import 'ad_results_page.dart';
import 'ad_studio_api.dart';

/// Admin "AI ads": images the admin creates with AI inside the app (instead of going to an AI app), to download and use anywhere.
/// An AI ad is not a listing and does not go on Explore.
class AdStudioPage extends StatefulWidget {
  final Future<List<AdDraft>> Function()? loadDrafts; // tests inject fakes
  final Future<void> Function(int id)? discardDraft;
  const AdStudioPage({super.key, this.loadDrafts, this.discardDraft});

  static const routeName = 'ad-studio';

  /// Bumped when an AI ad is added or removed, so the list reloads.
  static final ValueNotifier<int> changed = ValueNotifier(0);

  static Route<void> route() => MaterialPageRoute(settings: const RouteSettings(name: routeName), builder: (_) => const AdStudioPage());

  @override
  State<AdStudioPage> createState() => _AdStudioPageState();
}

class _AdStudioPageState extends State<AdStudioPage> {
  List<AdDraft>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    AdStudioPage.changed.addListener(_fetch);
    _fetch();
  }

  @override
  void dispose() {
    AdStudioPage.changed.removeListener(_fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _failed = false);
    try {
      final items = await (widget.loadDrafts ?? AdStudioApi().drafts)();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _delete(AdDraft d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('adstudio.delete_q'.tr()),
        content: Text(d.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('adstudio.cancel'.tr())),
          TextButton(key: const Key('ad-delete-confirm'), onPressed: () => Navigator.pop(c, true), child: Text('adstudio.delete'.tr(), style: const TextStyle(color: JV2.danger))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await (widget.discardDraft ?? AdStudioApi().discard)(d.id);
      if (mounted) setState(() => _items = _items!.where((x) => x.id != d.id).toList());
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: 'adstudio.failed'.tr(), icon: Icons.error_outline_rounded, iconColor: JV2.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdFlowScaffold(
      title: 'adstudio.title'.tr(),
      sub: 'adstudio.studio_sub'.tr(),
      right: const AdminPill(),
      bodyOverride: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kAdPad, 20, kAdPad, 30),
          children: [
            _NewAdCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdBriefPage()))),
            const SizedBox(height: 18),
            Text('adstudio.your_ads'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: JV2.ink)),
            const SizedBox(height: 10),
            if (_failed)
              _Note(text: 'adstudio.load_failed'.tr(), action: 'adstudio.retry'.tr(), onTap: _fetch)
            else if (_items == null)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
            else if (_items!.isEmpty)
              _Note(text: 'adstudio.empty'.tr())
            else
              for (final d in _items!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _AdRow(
                    key: Key('draft-${d.id}'),
                    draft: d,
                    meta: [
                      '${d.width}×${d.height}',
                      if (d.createdAt != null) DateFormat('d MMM', context.locale.languageCode).format(d.createdAt!),
                    ].join(' · '),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdResultsPage(api: AdStudioApi(), draft: d))),
                    onDelete: () => _delete(d),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _NewAdCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewAdCard({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('ad-new'),
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x420B2A4A), blurRadius: 34, offset: Offset(0, 16))]),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1), colors: [JV2.navyLift, JV2.navy])))),
        const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment(1, -1), radius: 1.1, colors: [Color(0x42E5C48F), Color(0x00E5C48F)], stops: [0, 0.55])))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const AdSpark(size: 13, color: Color(0xFFE5C48F)),
              const SizedBox(width: 7),
              Text('adstudio.create'.tr().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: Color(0xFFE5C48F))),
            ]),
            const SizedBox(height: 8),
            Text('adstudio.new_ad'.tr(), style: AdStyles.display(context, 25).copyWith(color: Colors.white, height: 1.1)),
            const SizedBox(height: 8),
            Text('adstudio.new_sub'.tr(), style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xCCFFFFFF))),
          ]),
        ),
      ]),
    ),
  );
}

class _AdRow extends StatelessWidget {
  final AdDraft draft;
  final String meta;
  final VoidCallback onTap, onDelete;
  const _AdRow({super.key, required this.draft, required this.meta, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final img = draft.variations.isEmpty ? null : draft.variations.first.imageUrl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: JV2.line), boxShadow: const [BoxShadow(color: Color(0x0F0B2A4A), blurRadius: 8, offset: Offset(0, 2))]),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 66, height: 46, child: img == null ? const ColoredBox(color: JV2.fillHi) : CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, errorWidget: (_, _, _) => const ColoredBox(color: JV2.fillHi)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(draft.title.isEmpty ? '—' : draft.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: JV2.ink)),
              const SizedBox(height: 3),
              Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
            ]),
          ),
          PopupMenuButton<String>(
            key: Key('draft-menu-${draft.id}'),
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: JV2.inkSub),
            onSelected: (_) => onDelete(),
            itemBuilder: (_) => [PopupMenuItem(value: 'delete', key: const Key('draft-discard'), child: Text('adstudio.delete'.tr(), style: const TextStyle(color: JV2.danger)))],
          ),
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onTap;
  const _Note({required this.text, this.action, this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: JV2.line)),
    child: Column(children: [
      Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: JV2.inkSub)),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ]),
  );
}
