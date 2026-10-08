import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../compounds/presentation/widgets/page_widgets.dart';
import '../data/search_api.dart';
import 'widgets/search_widgets.dart';

/// Every live launch and offer, with All / Launches / Offers tabs.
class LaunchesPage extends StatefulWidget {
  final SearchApi api;
  final void Function(PromotionItem) onOpen;
  const LaunchesPage({super.key, required this.api, required this.onOpen});

  @override
  State<LaunchesPage> createState() => _LaunchesPageState();
}

class _LaunchesPageState extends State<LaunchesPage> {
  List<PromotionItem>? _all;
  bool _failed = false;
  int _tab = 0; // 0 all · 1 launches · 2 offers

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final list = await widget.api.promotions(limit: 60);
      if (mounted) setState(() => _all = list);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = (_all ?? const <PromotionItem>[])
        .where((p) => _tab == 0 || p.type == (_tab == 1 ? 'launch' : 'offer'))
        .toList();
    final tabs = [
      'find.tab_all'.tr(),
      'find.tab_launches'.tr(),
      'find.tab_offers'.tr(),
    ];
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          SearchSubHeader(title: 'find.launches_title'.tr()),
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
                      Row(
                        children: [
                          for (var i = 0; i < tabs.length; i++)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 7),
                              child: GestureDetector(
                                onTap: () => setState(() => _tab = i),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: i == _tab ? JV2.navy : JV2.surface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: i == _tab ? JV2.navy : JV2.line,
                                    ),
                                  ),
                                  child: Text(
                                    tabs[i],
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: i == _tab
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: i == _tab
                                          ? Colors.white
                                          : JV2.inkSub,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (list.isEmpty)
                        EmptyBlock(
                          icon: Icons.local_offer_outlined,
                          title: 'find.launches_empty'.tr(),
                        )
                      else
                        for (final p in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: LaunchCard(
                              p: p,
                              wide: true,
                              onTap: () => widget.onOpen(p),
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
