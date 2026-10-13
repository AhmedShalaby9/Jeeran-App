import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../compounds/presentation/widgets/page_widgets.dart';
import '../../developers/presentation/widgets/developer_shimmer.dart';
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
  static const _pageSize = 20;
  final _scroll = ScrollController();
  final _items = <DeveloperSummary>[];
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
    if (_loading || _failed || _items.length >= _total) return;
    setState(() => _loading = true);
    await _fetch(_gen);
  }

  Future<void> _fetch(int gen) async {
    try {
      final r = await widget.api.developersPage(
        page: _page + 1,
        limit: _pageSize,
        q: _q,
      );
      if (!mounted || gen != _gen) return;
      setState(() {
        _page++;
        _total = r.total;
        _items.addAll(r.items);
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
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          SearchSubHeader(
            title: 'find.developers'.tr(),
            trailing: _total > 0 ? '$_total' : null,
          ),
          Expanded(
            child: _failed && _items.isEmpty
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
                          onPressed: _reload,
                          child: Text('explore.try_again'.tr()),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    controller: _scroll,
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
                                key: const Key('dev-q'),
                                onChanged: (v) {
                                  _q = v.trim();
                                  _reload();
                                },
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
                      if (_loading && _items.isEmpty)
                        const DevListShimmer()
                      else if (_items.isEmpty && _q.isEmpty && !_loading)
                        EmptyBlock(
                          icon: Icons.business_rounded,
                          title: 'find.dev_empty'.tr(),
                        )
                      else if (_items.isEmpty && !_loading)
                        EmptyBlock(
                          icon: Icons.search_off_rounded,
                          title: 'find.no_dev_title'.tr(),
                          sub: 'find.no_dev_sub'.tr(),
                        )
                      else
                        for (final d in _items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: DevListRow(
                              d: d,
                              onTap: () => widget.onOpen(d),
                            ),
                          ),
                      if (_loading && _items.isNotEmpty)
                        const DevListShimmer(rows: 2),
                      if (_failed)
                        Center(
                          child: TextButton(
                            onPressed: _more,
                            child: Text('explore.try_again'.tr()),
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
