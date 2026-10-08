import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
import '../data/search_api.dart';
import '../data/search_filters.dart';
import 'widgets/search_widgets.dart';

/// The full filter set, raised over the results. Every change re-counts against the server
/// (debounced) so the button always says how many listings you would get.
Future<SearchFilters?> showFilterSheet(
  BuildContext context, {
  required SearchApi api,
  required SearchFilters initial,
}) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x520B2A4A),
    builder: (_) => _FilterSheet(api: api, initial: initial),
  );
}

class _FilterSheet extends StatefulWidget {
  final SearchApi api;
  final SearchFilters initial;
  const _FilterSheet({required this.api, required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchFilters _f = widget.initial;
  int? _count;
  Timer? _debounce;
  int _seq = 0;
  List<AreaItem> _areas = const [];
  int _developerTotal = 0;
  late final TextEditingController _minSize = TextEditingController(
    text: _f.minSize?.toString() ?? '',
  );
  late final TextEditingController _maxSize = TextEditingController(
    text: _f.maxSize?.toString() ?? '',
  );

  @override
  void initState() {
    super.initState();
    _recount();
    widget.api
        .areas()
        .then((a) {
          if (mounted) setState(() => _areas = a);
        })
        .catchError((_) {});
    widget.api
        .developers()
        .then((d) {
          if (mounted) setState(() => _developerTotal = d.length);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _minSize.dispose();
    _maxSize.dispose();
    super.dispose();
  }

  void _set(SearchFilters next) {
    setState(() => _f = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _recount);
  }

  Future<void> _recount() async {
    final seq = ++_seq;
    if (mounted) setState(() => _count = null);
    try {
      final n = await widget.api.count(_f);
      if (mounted && seq == _seq) setState(() => _count = n);
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _count = null);
    }
  }

  void _reset() {
    _minSize.clear();
    _maxSize.clear();
    _set(SearchFilters(sort: _f.sort));
  }

  // ── pieces ──

  Widget _segment(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: JV2.inkSub,
        ),
      ),
      const SizedBox(height: 11),
      child,
    ],
  );

  Widget _chip(String text, bool on, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: on ? JV2.goldFilm : JV2.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: on ? JV2.goldEdge : JV2.line),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: on ? FontWeight.w700 : FontWeight.w600,
          color: on ? JV2.gold : JV2.inkSub,
        ),
      ),
    ),
  );

  Widget _wrap(List<Widget> kids) =>
      Wrap(spacing: 8, runSpacing: 8, children: kids);

  Widget _singleChips<T>(
    List<T> keys,
    String Function(T) label,
    T? current,
    void Function(T?) set,
  ) => _wrap([
    for (final k in keys)
      _chip(label(k), k == current, () => set(k == current ? null : k)),
  ]);

  Widget _counts(String? current, void Function(String?) set) => Row(
    children: [
      for (final c in SearchOptions.counts)
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: GestureDetector(
              onTap: () => set(c == current ? null : c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c == current ? JV2.navy : JV2.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: c == current ? JV2.navy : JV2.line),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: c == current
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: c == current ? Colors.white : JV2.inkSub,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _price() {
    final lo = (_f.minPrice ?? SearchOptions.priceMin).toDouble();
    final hi = (_f.maxPrice ?? SearchOptions.priceMax).toDouble();
    String m(double v, {bool plus = false}) =>
        '${(v / 1000000).toStringAsFixed(1)}M${plus ? '+' : ''}';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${m(lo)} ${'explore.egp'.tr()}',
              style: JV2.display(context, 19),
            ),
            Text(
              '${m(hi, plus: hi >= SearchOptions.priceMax)} ${'explore.egp'.tr()}',
              style: JV2.display(context, 19),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: JV2.goldHi,
            inactiveTrackColor: JV2.track,
            thumbColor: Colors.white,
            overlayColor: const Color(0x1FB8893D),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 3,
            ),
          ),
          child: RangeSlider(
            values: RangeValues(lo, hi),
            min: SearchOptions.priceMin.toDouble(),
            max: SearchOptions.priceMax.toDouble(),
            divisions: 49,
            onChanged: (v) => _set(
              _f.copyWith(
                minPrice: v.start <= SearchOptions.priceMin
                    ? null
                    : v.start.round(),
                maxPrice: v.end >= SearchOptions.priceMax
                    ? null
                    : v.end.round(),
              ),
            ),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1M', style: TextStyle(fontSize: 11, color: JV2.inkSub)),
            Text('50M+', style: TextStyle(fontSize: 11, color: JV2.inkSub)),
          ],
        ),
      ],
    );
  }

  Widget _sizeField(
    String label,
    TextEditingController c,
    void Function(int?) set,
  ) => Expanded(
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: JV2.line),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: JV2.inkMute,
            ),
          ),
          Expanded(
            child: TextField(
              controller: c,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              onChanged: (v) => set(int.tryParse(v.trim())),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: JV2.ink,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '—',
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _picker({
    required Widget leading,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JV2.line),
      ),
      child: Row(
        children: [
          leading,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                ),
              ],
            ),
          ),
          Icon(chevronIcon(context), size: 16, color: JV2.inkSub),
        ],
      ),
    ),
  );

  Widget _toggle(
    String title,
    String sub,
    bool value,
    ValueChanged<bool> set,
  ) => GestureDetector(
    onTap: () => set(!value),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JV2.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 28,
            padding: const EdgeInsets.all(3),
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: value
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [JV2.goldHi, JV2.gold],
                    )
                  : null,
              color: value ? null : JV2.fillHi,
            ),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickCompound() async {
    final ar = isArabic(context);
    final picked = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'find.pick_compound'.tr(),
        load: () async {
          final list = await widget.api.compounds();
          return [
            for (final c in list)
              _PickItem(
                id: c['id'] as int,
                name:
                    ((ar ? c['name_ar'] : c['name_en']) as String?)
                            ?.isNotEmpty ==
                        true
                    ? (ar ? c['name_ar'] : c['name_en']) as String
                    : (c['name_ar'] ?? c['name_en'] ?? '') as String,
                sub: () {
                  final d = c['developer'];
                  if (d is! Map) return '';
                  return ((ar ? d['name_ar'] : d['name_en']) ??
                          d['name_en'] ??
                          d['name_ar'] ??
                          '')
                      as String;
                }(),
                image: c['main_image'] as String?,
              ),
          ];
        },
      ),
    );
    if (picked != null && mounted) {
      _set(_f.copyWith(compoundId: picked['id'], compoundName: picked['name']));
    }
  }

  Future<void> _pickDeveloper() async {
    final ar = isArabic(context);
    final picked = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'find.pick_developer'.tr(),
        load: () async => [
          for (final d in await widget.api.developers())
            _PickItem(
              id: d.id,
              name: d.name(ar),
              sub:
                  '${'find.n_compounds'.plural(d.compounds)} · ${'find.n_units'.plural(d.units)}',
              image: d.logo,
            ),
        ],
      ),
    );
    if (picked != null && mounted) {
      _set(
        _f.copyWith(developerId: picked['id'], developerName: picked['name']),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final f = _f;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: JV2.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Color(0x380B2A4A),
              blurRadius: 50,
              offset: Offset(0, -20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: JV2.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kSearchPad, 6, kSearchPad, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'find.filters'.tr(),
                      style: JV2.display(context, 21),
                    ),
                  ),
                  GestureDetector(
                    onTap: _reset,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        'find.reset'.tr(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: JV2.inkSub,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: JV2.fillFaint,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: JV2.line),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: JV2.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: JV2.line),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  kSearchPad,
                  20,
                  kSearchPad,
                  20,
                ),
                children: [
                  _segment(
                    'find.s_status'.tr(),
                    _singleChips<String>(
                      SearchOptions.statuses,
                      (k) => 'find.st_$k'.tr(),
                      f.status,
                      (v) => _set(f.copyWith(status: v)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_type'.tr(),
                    _wrap([
                      for (final t in SearchOptions.types)
                        _chip(
                          'type.$t'.tr(),
                          f.types.contains(t),
                          () => _set(
                            f.copyWith(
                              types: f.types.contains(t)
                                  ? ({...f.types}..remove(t))
                                  : {...f.types, t},
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  _segment('find.s_price'.tr(), _price()),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_beds'.tr(),
                    _counts(f.beds, (v) => _set(f.copyWith(beds: v))),
                  ),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_baths'.tr(),
                    _counts(f.baths, (v) => _set(f.copyWith(baths: v))),
                  ),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_delivery'.tr(),
                    _singleChips<String>(
                      SearchOptions.deliveries,
                      (k) => k == 'ready' ? 'find.ready'.tr() : k,
                      f.delivery,
                      (v) => _set(f.copyWith(delivery: v)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_size'.tr(),
                    Row(
                      children: [
                        _sizeField(
                          'find.s_from'.tr(),
                          _minSize,
                          (v) => _set(_f.copyWith(minSize: v)),
                        ),
                        const SizedBox(width: 10),
                        _sizeField(
                          'find.s_to'.tr(),
                          _maxSize,
                          (v) => _set(_f.copyWith(maxSize: v)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_finishing'.tr(),
                    _singleChips<String>(
                      SearchOptions.finishings,
                      (k) => 'compound.fin_$k'.tr(),
                      f.finishing,
                      (v) => _set(f.copyWith(finishing: v)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_payment'.tr(),
                    _singleChips<String>(
                      SearchOptions.payments,
                      paymentLabel,
                      f.payment,
                      (v) => _set(f.copyWith(payment: v)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_amenities'.tr(),
                    _wrap([
                      for (final a in SearchOptions.amenities)
                        _chip(
                          'find.am_$a'.tr(),
                          f.amenities.contains(a),
                          () => _set(
                            f.copyWith(
                              amenities: f.amenities.contains(a)
                                  ? ({...f.amenities}..remove(a))
                                  : {...f.amenities, a},
                            ),
                          ),
                        ),
                    ]),
                  ),
                  if (_areas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _segment(
                      'find.s_area'.tr(),
                      _wrap([
                        for (final a in _areas)
                          _chip(
                            a.name(ar),
                            f.areaId == a.id,
                            () => _set(
                              f.areaId == a.id
                                  ? f.without('area')
                                  : f.copyWith(
                                      areaId: a.id,
                                      areaName: a.name(ar),
                                    ),
                            ),
                          ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_compound'.tr(),
                    _picker(
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: JV2.fillFaint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: JV2.line),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 18,
                          color: JV2.navy,
                        ),
                      ),
                      title: f.compoundName ?? 'find.any_compound'.tr(),
                      sub: f.compoundId == null
                          ? 'find.pick_compound'.tr()
                          : 'find.change'.tr(),
                      onTap: _pickCompound,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _segment(
                    'find.s_developer'.tr(),
                    _picker(
                      leading: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: JV2.fillFaint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: JV2.line),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 18,
                          color: JV2.navy,
                        ),
                      ),
                      title: f.developerName ?? 'find.any_developer'.tr(),
                      sub: f.developerId != null
                          ? 'find.change'.tr()
                          : (_developerTotal > 0
                                ? 'find.n_developers_now'.plural(
                                    _developerTotal,
                                  )
                                : 'find.pick_developer'.tr()),
                      onTap: _pickDeveloper,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _toggle(
                    'find.featured_only'.tr(),
                    'find.featured_sub'.tr(),
                    f.featured,
                    (v) => _set(f.copyWith(featured: v)),
                  ),
                  const SizedBox(height: 12),
                  _toggle(
                    'find.verified_only'.tr(),
                    'find.verified_sub'.tr(),
                    f.verifiedOnly,
                    (v) => _set(f.copyWith(verifiedOnly: v)),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                kSearchPad,
                14,
                kSearchPad,
                MediaQuery.of(context).padding.bottom + 14,
              ),
              decoration: const BoxDecoration(
                color: JV2.surface,
                border: Border(top: BorderSide(color: JV2.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'find.matching_now'.tr(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: JV2.inkSub,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _count == null
                              ? '…'
                              : 'find.n_matching'.plural(
                                  _count!,
                                  format: NumberFormat.decimalPattern(
                                    context.locale.toString(),
                                  ),
                                ),
                          style: JV2.display(context, 20),
                        ),
                      ],
                    ),
                  ),
                  JV2PrimaryButton(
                    width: 150,
                    height: 50,
                    onPressed: () => Navigator.pop(context, _f),
                    child: Text('find.show_results'.tr()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickItem {
  final int id;
  final String name;
  final String sub;
  final String? image;
  const _PickItem({
    required this.id,
    required this.name,
    required this.sub,
    this.image,
  });
}

/// Searchable list used for the compound and developer pickers. Pops `{id, name}` or null.
class _PickerSheet extends StatefulWidget {
  final String title;
  final Future<List<_PickItem>> Function() load;
  const _PickerSheet({required this.title, required this.load});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  List<_PickItem>? _items;
  bool _failed = false;
  String _q = '';

  @override
  void initState() {
    super.initState();
    widget
        .load()
        .then((v) {
          if (mounted) setState(() => _items = v);
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    final list = (_items ?? const <_PickItem>[])
        .where(
          (i) =>
              i.name.toLowerCase().contains(_q.toLowerCase()) ||
              i.sub.toLowerCase().contains(_q.toLowerCase()),
        )
        .toList();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: JV2.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: JV2.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kSearchPad, 8, kSearchPad, 12),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(widget.title, style: JV2.display(context, 21)),
                  ),
                  const SizedBox(height: 12),
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
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'find.search_hint'.tr(),
                            ),
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: JV2.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _failed
                  ? Center(child: Text('find.load_failed'.tr(), style: JV2.sub))
                  : _items == null
                  ? const Center(
                      child: CircularProgressIndicator(color: JV2.navy),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        kSearchPad,
                        0,
                        kSearchPad,
                        24,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = list[i];
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, {
                            'id': it.id,
                            'name': it.name,
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: JV2.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: JV2.line),
                            ),
                            child: Row(
                              children: [
                                Photo(
                                  url: it.image,
                                  width: 38,
                                  height: 38,
                                  radius: 11,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: JV2.ink,
                                        ),
                                      ),
                                      if (it.sub.isNotEmpty)
                                        Text(
                                          it.sub,
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
