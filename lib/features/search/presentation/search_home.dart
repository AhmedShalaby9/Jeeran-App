import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/jv2.dart';
import '../../ai_chat/presentation/session/pages/ai_chat_history_page.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/presentation/pages/property_details_page.dart';
import '../data/recent_searches.dart';
import '../data/search_api.dart';
import '../data/search_filters.dart';
import 'all_developers_page.dart';
import 'filter_sheet.dart';
import 'launches_page.dart';
import 'widgets/search_widgets.dart';

enum _View { browse, entry, results }

/// The Search tab: Browse (developers → launches → every unit), Entry (type or pick a recent),
/// and Results (a real query with removable chips). The filter builder is a sheet over them.
class SearchHome extends StatefulWidget {
  final ValueNotifier<bool>? resetNotifier;
  final SearchApi? api; // tests inject a fake
  const SearchHome({super.key, this.resetNotifier, this.api});

  @override
  State<SearchHome> createState() => _SearchHomeState();
}

class _SearchHomeState extends State<SearchHome> {
  late final SearchApi _api = widget.api ?? SearchApi(sl<ApiClient>());
  final _scroll = ScrollController();
  final _entryCtrl = TextEditingController();

  _View _view = _View.browse;
  _View _from = _View.browse; // where Back from Entry returns to
  SearchFilters _f = const SearchFilters();

  // browse rails
  List<DeveloperSummary>? _devs;
  List<PromotionItem>? _promos;
  List<AreaItem> _areas = const [];

  // the list
  List<Map<String, dynamic>>? _items; // null = loading
  int _total = 0;
  int _page = 1;
  int _pages = 1;
  bool _loadingMore = false;
  bool _failed = false;
  List<RelaxSuggestion> _relax = const [];
  int _seq = 0;

  // entry
  Timer? _suggestTimer;
  Suggestions _suggestions = Suggestions.empty;
  List<SearchFilters> _recents = const [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    widget.resetNotifier?.addListener(_reset);
    _loadRails();
    _reload();
  }

  @override
  void dispose() {
    widget.resetNotifier?.removeListener(_reset);
    _suggestTimer?.cancel();
    _scroll.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── loading ──

  Future<void> _loadRails() async {
    _api
        .developers(limit: 10)
        .then((d) {
          if (mounted) setState(() => _devs = d);
        })
        .catchError((_) {
          if (mounted) setState(() => _devs = const []);
        });
    _api
        .promotions(limit: 10)
        .then((p) {
          if (mounted) setState(() => _promos = p);
        })
        .catchError((_) {
          if (mounted) setState(() => _promos = const []);
        });
    _api
        .areas()
        .then((a) {
          if (mounted) setState(() => _areas = a);
        })
        .catchError((_) {});
  }

  Future<void> _reload() async {
    final seq = ++_seq;
    setState(() {
      _items = null;
      _failed = false;
      _relax = const [];
      _page = 1;
    });
    try {
      final res = await _api.properties(_f);
      if (!mounted || seq != _seq) return;
      setState(() {
        _items = res.items;
        _total = res.total;
        _pages = res.pages;
      });
      if (res.items.isEmpty && _f.isActive) {
        final r = await _api.relax(_f).catchError((_) => <RelaxSuggestion>[]);
        if (mounted && seq == _seq) setState(() => _relax = r);
      }
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items == null || _page >= _pages) return;
    final seq = _seq;
    setState(() => _loadingMore = true);
    try {
      final res = await _api.properties(_f, page: _page + 1);
      if (!mounted || seq != _seq) return;
      setState(() {
        _items = [..._items!, ...res.items];
        _page += 1;
        _pages = res.pages;
      });
    } catch (_) {
      // keep what we have; the next scroll tries again
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 400) _loadMore();
  }

  // ── actions ──

  void _apply(
    SearchFilters next, {
    bool toResults = false,
    bool remember = true,
  }) {
    setState(() {
      _f = next;
      if (toResults) _view = _View.results;
      if (_view == _View.results && !next.isActive) _view = _View.browse;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (toResults && remember) RecentSearches.add(next);
    _reload();
  }

  void _reset() {
    _entryCtrl.clear();
    setState(() => _view = _View.browse);
    _apply(const SearchFilters());
  }

  void _openEntry() {
    _entryCtrl.text = _f.q;
    _entryCtrl.selection = TextSelection.collapsed(
      offset: _entryCtrl.text.length,
    );
    setState(() {
      _from = _view;
      _view = _View.entry;
      _suggestions = Suggestions.empty;
      _recents = RecentSearches.all();
    });
  }

  void _onEntryChanged(String text) {
    _suggestTimer?.cancel();
    if (text.trim().length < 2) {
      setState(() => _suggestions = Suggestions.empty);
      return;
    }
    _suggestTimer = Timer(const Duration(milliseconds: 280), () async {
      try {
        final s = await _api.suggest(text.trim());
        if (mounted && _entryCtrl.text.trim() == text.trim())
          setState(() => _suggestions = s);
      } catch (_) {}
    });
  }

  Future<void> _openFilters() async {
    final next = await showFilterSheet(context, api: _api, initial: _f);
    if (next != null && mounted) _apply(next, toResults: next.isActive);
  }

  void _openUnit(Map<String, dynamic> raw) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PropertyDetailsPage(property: PropertyModel.fromJson(raw)),
      ),
    );
  }

  void _openAsk() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AiChatHistoryPage()),
  );

  void _openDevelopers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AllDevelopersPage(
          api: _api,
          onOpen: (d) {
            Navigator.pop(ctx);
            _pickDeveloper(d);
          },
        ),
      ),
    );
  }

  void _openLaunches() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => LaunchesPage(
          api: _api,
          onOpen: (p) {
            Navigator.pop(ctx);
            _pickPromotion(p);
          },
        ),
      ),
    );
  }

  void _pickDeveloper(DeveloperSummary d) => _apply(
    SearchFilters(developerId: d.id, developerName: d.name(isArabic(context))),
    toResults: true,
  );

  void _pickPromotion(PromotionItem p) => _apply(
    SearchFilters(
      compoundId: p.compoundId,
      compoundName: p.compoundName(isArabic(context)),
    ),
    toResults: true,
  );

  // ── build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      resizeToAvoidBottomInset: false,
      body: switch (_view) {
        _View.entry => _entry(),
        _View.results => _results(),
        _View.browse => _browse(),
      },
    );
  }

  // ── browse ──

  Widget _browse() {
    final ar = isArabic(context);
    return Column(
      children: [
        SearchQueryBar(query: '', onTap: _openEntry),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.only(top: 18, bottom: 30),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSearchPad),
                child: AskCard(onTap: _openAsk),
              ),
              const SizedBox(height: 24),
              if (_devs == null || _devs!.isNotEmpty) ...[
                SearchSectionHead(
                  eyebrow: 'find.devs_eyebrow'.tr(),
                  title: 'find.devs_title'.tr(),
                  onAction: _openDevelopers,
                ),
                SizedBox(
                  height: 186,
                  child: _devs == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: JV2.navy,
                            strokeWidth: 2,
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: kSearchPad,
                          ),
                          itemCount: _devs!.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 11),
                          itemBuilder: (_, i) => DevRailCard(
                            d: _devs![i],
                            onTap: () => _pickDeveloper(_devs![i]),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
              if (_promos == null || _promos!.isNotEmpty) ...[
                SearchSectionHead(
                  eyebrow: 'find.launches_eyebrow'.tr(),
                  title: 'find.launches_title'.tr(),
                  onAction: _openLaunches,
                ),
                SizedBox(
                  height: 190,
                  child: _promos == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: JV2.navy,
                            strokeWidth: 2,
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: kSearchPad,
                          ),
                          itemCount: _promos!.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => LaunchCard(
                            p: _promos![i],
                            onTap: () => _pickPromotion(_promos![i]),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
              SearchSectionHead(
                eyebrow: 'find.units_eyebrow'.tr(),
                title: 'find.units_title'.tr(),
              ),
              _quickBar(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSearchPad),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _items == null
                            ? 'find.searching'.tr()
                            : 'find.units_listed'.plural(
                                _total,
                                format: NumberFormat.decimalPattern(
                                  context.locale.toString(),
                                ),
                              ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: JV2.inkSub,
                        ),
                      ),
                    ),
                    SortMenu(
                      sort: _f.sort,
                      onPick: (s) => _apply(_f.copyWith(sort: s)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSearchPad),
                child: _list(ar),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The Filters button and the four quick narrowers.
  Widget _quickBar() {
    final f = _f;
    String? priceKey;
    for (final e in SearchOptions.priceBands.entries) {
      if (e.value.$1 == f.minPrice && e.value.$2 == f.maxPrice)
        priceKey = e.key;
    }
    final typeValue = f.types.isEmpty
        ? null
        : f.types.map((t) => 'type.$t'.tr()).join(' · ');
    String bedsLabel(String b) =>
        b == '5+' ? 'find.beds_plus'.tr() : 'find.n_beds'.plural(int.parse(b));
    final deliveryLabel = f.delivery == null
        ? null
        : (f.delivery == 'ready' ? 'find.ready'.tr() : f.delivery!);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kSearchPad),
        children: [
          FiltersButton(count: f.activeCount, onTap: _openFilters),
          const SizedBox(width: 8),
          QuickChip<String>(
            label: 'find.chip_type'.tr(),
            value: typeValue,
            selected: f.types.length == 1 ? f.types.first : null,
            options: [
              (null, 'find.any_type'.tr()),
              for (final t in SearchOptions.quickTypes) (t, 'type.$t'.tr()),
            ],
            onPick: (v) =>
                _apply(f.copyWith(types: v == null ? const {} : {v})),
          ),
          const SizedBox(width: 8),
          QuickChip<String>(
            label: 'find.chip_beds'.tr(),
            value: f.beds == null ? null : bedsLabel(f.beds!),
            selected: f.beds,
            options: [
              (null, 'find.any'.tr()),
              for (final b in SearchOptions.counts) (b, bedsLabel(b)),
            ],
            onPick: (v) => _apply(f.copyWith(beds: v)),
          ),
          const SizedBox(width: 8),
          QuickChip<String>(
            label: 'find.chip_price'.tr(),
            value: priceKey == null ? null : 'find.band_$priceKey'.tr(),
            selected: priceKey,
            options: [
              (null, 'find.any_price'.tr()),
              for (final k in SearchOptions.priceBands.keys)
                (k, 'find.band_$k'.tr()),
            ],
            onPick: (v) {
              final band = v == null ? null : SearchOptions.priceBands[v];
              _apply(f.copyWith(minPrice: band?.$1, maxPrice: band?.$2));
            },
          ),
          const SizedBox(width: 8),
          QuickChip<String>(
            label: 'find.chip_delivery'.tr(),
            value: deliveryLabel,
            selected: f.delivery,
            options: [
              (null, 'find.any'.tr()),
              for (final d in SearchOptions.deliveries)
                (d, d == 'ready' ? 'find.ready'.tr() : d),
            ],
            onPick: (v) => _apply(f.copyWith(delivery: v)),
          ),
        ],
      ),
    );
  }

  /// Rows, skeleton, retry or the "nothing matches" state, then the load-more spinner.
  Widget _list(bool ar) {
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Text('find.load_failed'.tr(), style: JV2.display(context, 20)),
            const SizedBox(height: 14),
            JV2PrimaryButton(
              width: 150,
              height: 44,
              onPressed: _reload,
              child: Text('explore.try_again'.tr()),
            ),
          ],
        ),
      );
    }
    if (_items == null) return const ResultsSkeleton();
    if (_items!.isEmpty) return _empty();
    return Column(
      children: [
        for (final raw in _items!)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: UnitRow(unit: UnitView(raw), onTap: () => _openUnit(raw)),
          ),
        if (_loadingMore || _page < _pages)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: JV2.goldHi,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _empty() {
    final s = _relax.isEmpty ? null : _relax.first;
    String? sub;
    String? button;
    if (s != null) {
      final nf = NumberFormat.decimalPattern(context.locale.toString());
      switch (s.kind) {
        case 'raise_max_price':
          sub = 'find.raise_sub'.tr(
            args: [compactPrice(s.price!.toDouble()), nf.format(s.count)],
          );
          button = 'find.raise_btn'.tr(
            args: [compactPrice(s.price!.toDouble())],
          );
        case 'lower_min_price':
          sub = 'find.lower_sub'.tr(
            args: [compactPrice(s.price!.toDouble()), nf.format(s.count)],
          );
          button = 'find.lower_btn'.tr(
            args: [compactPrice(s.price!.toDouble())],
          );
        case 'drop_filter':
          final name = 'find.fn_${s.filter}'.tr();
          sub = 'find.drop_sub'.tr(args: [name, nf.format(s.count)]);
          button = 'find.drop_btn'.tr(args: [name]);
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 44, 10, 10),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: JV2.fillFaint,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: JV2.line),
            ),
            child: const Icon(Icons.search_rounded, color: JV2.inkSub),
          ),
          const SizedBox(height: 14),
          Text('find.empty_title'.tr(), style: JV2.display(context, 21)),
          const SizedBox(height: 10),
          Text(
            sub ?? 'find.empty_plain'.tr(),
            textAlign: TextAlign.center,
            style: JV2.sub.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (s != null && button != null)
            JV2PrimaryButton(
              width: 220,
              height: 46,
              onPressed: () =>
                  _apply(s.applyTo(_f), toResults: _view == _View.results),
              child: Text(button),
            )
          else if (_f.isActive)
            JV2PrimaryButton(
              width: 200,
              height: 46,
              onPressed: _reset,
              child: Text('find.reset_all'.tr()),
            ),
        ],
      ),
    );
  }

  // ── results ──

  Widget _results() {
    final chips = activeChips(context, _f);
    final nf = NumberFormat.decimalPattern(context.locale.toString());
    final headline = _items == null
        ? 'find.searching'.tr()
        : _total == 0
        ? 'find.no_matches'.tr()
        : [
            'find.n_results'.plural(_total, format: nf),
            if (_f.areaName != null) 'find.in_area'.tr(args: [_f.areaName!]),
          ].join(' ');
    return Column(
      children: [
        SearchQueryBar(
          query: filterSummary(context, _f),
          showBack: true,
          onBack: _reset,
          onTap: _openEntry,
          onClear: _f.q.trim().isEmpty ? null : () => _apply(_f.without('q')),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: 26),
            children: [
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    kSearchPad,
                    12,
                    kSearchPad,
                    4,
                  ),
                  itemCount: chips.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => i == 0
                      ? FiltersButton(
                          count: _f.activeCount,
                          onTap: _openFilters,
                        )
                      : RemovableChip(
                          label: chips[i - 1].$1,
                          onRemove: () => _apply(chips[i - 1].$2),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kSearchPad,
                  12,
                  kSearchPad,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: JV2.inkSub,
                        ),
                      ),
                    ),
                    SortMenu(
                      sort: _f.sort,
                      onPick: (s) => _apply(_f.copyWith(sort: s)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSearchPad),
                child: _list(isArabic(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── entry ──

  Widget _entry() {
    final ar = isArabic(context);
    final text = _entryCtrl.text.trim();
    final typing = text.length >= 2;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            kSearchPad,
            MediaQuery.of(context).padding.top + 8,
            kSearchPad,
            12,
          ),
          decoration: const BoxDecoration(
            color: Color(0xE6FAFBFD),
            border: Border(bottom: BorderSide(color: JV2.line)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _view = _from),
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
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: JV2.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: JV2.goldEdge),
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
                          controller: _entryCtrl,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onChanged: (v) {
                            setState(() {});
                            _onEntryChanged(v);
                          },
                          onSubmitted: (v) => v.trim().isEmpty
                              ? null
                              : _apply(
                                  _f.copyWith(q: v.trim()),
                                  toResults: true,
                                ),
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: JV2.ink,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'find.placeholder'.tr(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 18, bottom: 30),
            children: typing ? _suggestionRows(text, ar) : _entryIdle(ar),
          ),
        ),
      ],
    );
  }

  List<Widget> _suggestionRows(String text, bool ar) {
    String nameOf(Map<String, dynamic> m) {
      final a = (m['name_ar'] as String?) ?? '';
      final e = (m['name_en'] as String?) ?? '';
      return ar ? (a.isNotEmpty ? a : e) : (e.isNotEmpty ? e : a);
    }

    Widget row(IconData icon, String title, String? sub, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kSearchPad,
              vertical: 11,
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: JV2.inkSub),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: JV2.ink,
                        ),
                      ),
                      if (sub != null && sub.isNotEmpty)
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: JV2.inkSub,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    Widget head(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(kSearchPad, 14, kSearchPad, 4),
      child: Text(
        t.toUpperCase(),
        style: JV2.eyebrow.copyWith(fontSize: 10, letterSpacing: 1.8),
      ),
    );

    final s = _suggestions;
    return [
      row(
        Icons.search_rounded,
        'find.sg_search_for'.tr(args: [text]),
        null,
        () => _apply(_f.copyWith(q: text), toResults: true),
      ),
      if (s.compounds.isNotEmpty) head('find.sg_compounds'.tr()),
      for (final c in s.compounds)
        row(
          Icons.apartment_rounded,
          nameOf(c),
          (c['developer'] is Map)
              ? nameOf(c['developer'] as Map<String, dynamic>)
              : null,
          () => _apply(
            SearchFilters(compoundId: c['id'] as int, compoundName: nameOf(c)),
            toResults: true,
          ),
        ),
      if (s.developers.isNotEmpty) head('find.sg_developers'.tr()),
      for (final d in s.developers)
        row(
          Icons.business_rounded,
          nameOf(d),
          null,
          () => _apply(
            SearchFilters(
              developerId: d['id'] as int,
              developerName: nameOf(d),
            ),
            toResults: true,
          ),
        ),
      if (s.areas.isNotEmpty) head('find.sg_areas'.tr()),
      for (final a in s.areas)
        row(
          Icons.place_outlined,
          nameOf(a),
          null,
          () => _apply(
            SearchFilters(areaId: a['id'] as int, areaName: nameOf(a)),
            toResults: true,
          ),
        ),
    ];
  }

  List<Widget> _entryIdle(bool ar) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSearchPad),
        child: AskCard(onTap: _openAsk),
      ),
      const SizedBox(height: 26),
      if (_recents.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(kSearchPad, 0, kSearchPad, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'find.recent_eyebrow'.tr().toUpperCase(),
                      style: JV2.eyebrow.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'find.recent_title'.tr(),
                      style: JV2.display(context, 24),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await RecentSearches.clear();
                  if (mounted) setState(() => _recents = const []);
                },
                child: Text(
                  'find.clear'.tr(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final r in _recents)
          GestureDetector(
            onTap: () => _apply(r, toResults: true),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kSearchPad,
                vertical: 11,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 17,
                    color: JV2.inkSub,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      _recentLabel(r),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, color: JV2.ink),
                    ),
                  ),
                  Icon(chevronIcon(context), size: 14, color: JV2.inkSub),
                ],
              ),
            ),
          ),
        const SizedBox(height: 22),
      ],
      if (_areas.isNotEmpty) ...[
        SearchSectionHead(
          eyebrow: 'find.popular'.tr(),
          title: 'find.browse_area'.tr(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSearchPad),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              for (final a in _areas)
                GestureDetector(
                  onTap: () => _apply(
                    SearchFilters(areaId: a.id, areaName: a.name(ar)),
                    toResults: true,
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: JV2.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: JV2.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Photo(
                            url: a.image,
                            radius: 0,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.name(ar),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: JV2.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'find.area_listings'.plural(
                                  a.listings,
                                  format: NumberFormat.decimalPattern(
                                    context.locale.toString(),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: JV2.inkSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  String _recentLabel(SearchFilters r) {
    final text = filterSummary(context, r);
    return text.isEmpty ? '—' : text;
  }
}
