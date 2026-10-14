import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/jv2.dart';
import '../../../compounds/presentation/pages/compound_page.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../search/data/search_api.dart';
import '../../../search/presentation/widgets/search_widgets.dart';
import '../widgets/explore_widgets.dart' show Photo, isArabic;

/// Every live compound: find by compound or developer name, narrow by area, a page at a time.
class AllCompoundsPage extends StatefulWidget {
  final SearchApi api;
  const AllCompoundsPage({super.key, required this.api});

  @override
  State<AllCompoundsPage> createState() => _AllCompoundsPageState();
}

class _AllCompoundsPageState extends State<AllCompoundsPage> {
  static const _pageSize = 20;
  final _scroll = ScrollController();
  final _items = <ProjectModel>[];
  List<AreaItem> _areas = const [];
  int? _areaId;
  String _q = '';
  int _page = 0, _total = 0;
  bool _loading = true, _failed = false;
  int _gen = 0; // a newer search makes older answers stale

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _more();
    });
    widget.api
        .areas()
        .then((a) {
          if (mounted) setState(() => _areas = a);
        })
        .catchError((_) {});
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final gen = ++_gen;
    setState(() {
      _items.clear();
      _page = 0;
      _total = 0;
      _loading = true;
      _failed = false;
    });
    await _fetch(gen);
  }

  Future<void> _more() async {
    if (_loading || _items.length >= _total) return;
    setState(() => _loading = true);
    await _fetch(_gen);
  }

  Future<void> _fetch(int gen) async {
    try {
      final r = await widget.api.compoundsPage(
        page: _page + 1,
        limit: _pageSize,
        q: _q,
        areaId: _areaId,
      );
      if (!mounted || gen != _gen) return;
      setState(() {
        _page++;
        _total = r.total;
        _items.addAll(r.items.map(ProjectModel.fromJson));
        _loading = false;
      });
    } catch (_) {
      if (mounted && gen == _gen) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          SearchSubHeader(
            title: 'explore.all_compounds'.tr(),
            trailing: _total > 0 ? '$_total' : null,
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
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
                        color: JV2.inkMute,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextField(
                          key: const Key('compound-q'),
                          onChanged: (v) {
                            _q = v.trim();
                            _reload();
                          },
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: JV2.ink,
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: false,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintText: 'explore.find_compound'.tr(),
                            hintStyle: const TextStyle(color: JV2.inkMute),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip(
                        'explore.area_all'.tr(),
                        _areaId == null,
                        () {
                          _areaId = null;
                          _reload();
                        },
                        const Key('area-all'),
                      ),
                      for (final a in _areas)
                        _chip(a.name(ar), _areaId == a.id, () {
                          _areaId = a.id;
                          _reload();
                        }, Key('area-${a.id}')),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final p in _items) _row(p, ar),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: JV2.goldHi,
                      ),
                    ),
                  ),
                if (_failed)
                  Center(
                    child: TextButton(
                      onPressed: _reload,
                      child: Text('explore.try_again'.tr()),
                    ),
                  ),
                if (!_loading && !_failed && _items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'explore.no_compound'.tr(),
                        textAlign: TextAlign.center,
                        style: JV2.sub.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap, Key key) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? JV2.navy : JV2.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? JV2.navy : JV2.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
            color: on ? Colors.white : JV2.ink,
          ),
        ),
      ),
    ),
  );

  Widget _row(ProjectModel p, bool ar) {
    final dev = p.developer?.name;
    final area = (ar ? p.areaAr : p.areaEn) ?? p.areaLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        key: Key('compound-row-${p.id}'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompoundPage(compoundId: p.id, name: p.name),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JV2.line),
          ),
          child: Row(
            children: [
              Photo(url: p.coverImage, width: 72, height: 60, radius: 11),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar
                          ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn)
                          : (p.nameEn.isNotEmpty ? p.nameEn : p.nameAr),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: JV2.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (dev != null && dev.isNotEmpty) dev,
                        if (area != null && area.isNotEmpty) area,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                    ),
                    if (p.minPrice != null || (p.unitsCount ?? 0) > 0) ...[
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (p.minPrice != null)
                            'explore.top_from'.tr(
                              args: [_compact(p.minPrice!)],
                            ),
                          if ((p.unitsCount ?? 0) > 0)
                            'explore.top_units'.tr(args: ['${p.unitsCount}']),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: JV2.ink),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isArabic(context)
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: JV2.inkMute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _compact(double n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}M';
  }
  return '${(n / 1000).round()}K';
}
