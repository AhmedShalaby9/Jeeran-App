import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../compounds/presentation/widgets/page_widgets.dart';
import '../data/search_api.dart';
import 'widgets/search_widgets.dart';

/// Every developer with live listings, ranked by inventory, with a find-as-you-type box.
class AllDevelopersPage extends StatefulWidget {
  final SearchApi api;
  final void Function(DeveloperSummary) onOpen;
  const AllDevelopersPage({super.key, required this.api, required this.onOpen});

  @override
  State<AllDevelopersPage> createState() => _AllDevelopersPageState();
}

class _AllDevelopersPageState extends State<AllDevelopersPage> {
  List<DeveloperSummary>? _all;
  bool _failed = false;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final list = await widget.api.developers();
      if (mounted) setState(() => _all = list);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = (_all ?? const <DeveloperSummary>[])
        .where(
          (d) =>
              q.isEmpty ||
              d.nameAr.toLowerCase().contains(q) ||
              d.nameEn.toLowerCase().contains(q),
        )
        .toList();
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          SearchSubHeader(
            title: 'find.developers'.tr(),
            trailing: _all == null ? null : '${_all!.length}',
          ),
          Expanded(
            child: _failed
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'explore.load_failed'.tr(),
                          style: JV2.display(context, 22),
                        ),
                        const SizedBox(height: 16),
                        JV2PrimaryButton(
                          width: 160,
                          height: 46,
                          onPressed: _load,
                          child: Text('explore.try_again'.tr()),
                        ),
                      ],
                    ),
                  )
                : _all == null
                ? const Center(
                    child: CircularProgressIndicator(color: JV2.navy),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      kSearchPad,
                      16,
                      kSearchPad,
                      30,
                    ),
                    children: [
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: JV2.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: JV2.line),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: JV2.inkSub,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _q = v),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: JV2.ink,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'find.find_dev'.tr(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_all!.isEmpty)
                        EmptyBlock(
                          icon: Icons.business_rounded,
                          title: 'find.dev_empty'.tr(),
                        )
                      else if (list.isEmpty)
                        EmptyBlock(
                          icon: Icons.search_off_rounded,
                          title: 'find.no_dev_title'.tr(),
                          sub: 'find.no_dev_sub'.tr(),
                        )
                      else
                        for (final d in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: DevListRow(
                              d: d,
                              onTap: () => widget.onOpen(d),
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
