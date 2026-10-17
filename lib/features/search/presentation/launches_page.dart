import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../explore/presentation/widgets/explore_widgets.dart'
    show chevronIcon;
import '../../compounds/presentation/widgets/page_widgets.dart';
import '../data/search_api.dart';
import 'offers_page.dart';
import 'widgets/list_shimmers.dart';
import 'widgets/search_widgets.dart';

/// Every live launch and offer, with All / Launches / Offers tabs.
class LaunchesPage extends StatefulWidget {
  final SearchApi api;
  final void Function(PromotionItem) onOpen;

  /// 0 all · 1 launches · 2 offers (Explore's two tiles open the matching tab).
  final int initialTab;
  const LaunchesPage({
    super.key,
    required this.api,
    required this.onOpen,
    this.initialTab = 0,
  });

  @override
  State<LaunchesPage> createState() => _LaunchesPageState();
}

class _LaunchesPageState extends State<LaunchesPage> {
  List<PromotionItem>? _all;
  PropertyFacets? _facets; // how many units carry a launch / offer mark
  bool _failed = false;
  late int _tab = widget.initialTab; // 0 all · 1 launches · 2 offers

  @override
  void initState() {
    super.initState();
    _load();
    widget.api
        .facets()
        .then((x) {
          if (mounted) setState(() => _facets = x);
        })
        .catchError((_) {});
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
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(
                      kSearchPad,
                      16,
                      kSearchPad,
                      30,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [LaunchCardShimmer(count: 4)],
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
                      if (_tab != 0 &&
                          _facets != null &&
                          (_tab == 1 ? _facets!.launch : _facets!.offer) >
                              0) ...[
                        _unitsBanner(_tab == 1),
                        const SizedBox(height: 14),
                      ],
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

  /// The unit-level launches / offers (the imported developer inventory): opens the list of units.
  Widget _unitsBanner(bool launches) {
    final n = launches ? _facets!.launch : _facets!.offer;
    final nf = NumberFormat.decimalPattern(context.locale.toString());
    return GestureDetector(
      key: const Key('units-banner'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OffersPage(api: widget.api, launches: launches),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: JV2.goldFilm,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JV2.goldEdge),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (launches
                            ? 'find.units_banner_launches'
                            : 'find.units_banner_offers')
                        .tr(namedArgs: {'n': nf.format(n)}),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'find.units_banner_sub'.tr(),
                    style: const TextStyle(fontSize: 12, color: JV2.inkSub),
                  ),
                ],
              ),
            ),
            Icon(chevronIcon(context), size: 18, color: JV2.gold),
          ],
        ),
      ),
    );
  }
}
