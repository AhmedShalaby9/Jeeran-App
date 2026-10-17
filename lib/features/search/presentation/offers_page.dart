import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/jv2.dart';
import '../../compounds/presentation/widgets/page_widgets.dart' show EmptyBlock;
import '../../properties/data/models/property_model.dart';
import '../../properties/domain/entities/property.dart';
import '../../units/presentation/unit_card.dart';
import '../data/search_api.dart';
import '../data/search_filters.dart';
import 'widgets/list_shimmers.dart';
import 'widgets/search_widgets.dart';

/// The units that have an offer or are part of a launch (design D5b): chips to narrow, then the unit cards.
class OffersPage extends StatefulWidget {
  final SearchApi api;
  final bool launches; // opens on Launch instead of Offer
  const OffersPage({super.key, required this.api, this.launches = false});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late SearchFilters _f = SearchFilters(
    offer: !widget.launches,
    launch: widget.launches,
  );
  final _scroll = ScrollController();
  final List<Property> _items = [];
  int _total = 0;
  int _page = 1;
  int _pages = 1;
  bool _loading = true;
  bool _failed = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400 &&
          !_loading &&
          _page < _pages)
        _load(more: true);
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _failed = false;
      if (!more) {
        _items.clear();
        _page = 1;
      }
    });
    try {
      final res = await widget.api.properties(_f, page: more ? _page + 1 : 1);
      if (!mounted || seq != _seq) return;
      setState(() {
        _items.addAll(res.items.map(PropertyModel.fromJson));
        _total = res.total;
        _page = more ? _page + 1 : 1;
        _pages = res.pages;
        _loading = false;
      });
    } catch (_) {
      if (mounted && seq == _seq) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _apply(SearchFilters next) {
    _f = next;
    _load();
  }

  Widget _chip(
    String label,
    bool on,
    VoidCallback onTap, {
    Key? key,
    bool close = false,
  }) => GestureDetector(
    key: key,
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? JV2.navy : JV2.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: on ? JV2.navy : JV2.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              color: on ? Colors.white : JV2.ink,
            ),
          ),
          if (on && close) ...[
            const SizedBox(width: 6),
            const Icon(Icons.close_rounded, size: 13, color: Colors.white),
          ],
        ],
      ),
    ),
  );

  Future<void> _pickDelivery() async {
    final v = await _pickOne(
      SearchOptions.deliveries.map((d) => (d, deliveryLabel(d))).toList(),
      _f.delivery,
    );
    if (v != null) _apply(_f.copyWith(delivery: v == '' ? null : v));
  }

  Future<void> _pickDown() async {
    final v = await _pickOne(
      SearchOptions.downPayments
          .map((d) => (d, d == '0' ? '0%' : '≤ $d%'))
          .toList(),
      _f.maxDown,
    );
    if (v != null) _apply(_f.copyWith(maxDown: v == '' ? null : v));
  }

  /// A small sheet of choices; '' means "clear it".
  Future<String?> _pickOne(
    List<(String, String)> options,
    String? current,
  ) => showModalBottomSheet<String>(
    context: context,
    backgroundColor: JV2.bgDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in [('', 'find.any'.tr()), ...options])
              GestureDetector(
                key: Key('pick-${value.isEmpty ? 'any' : value}'),
                onTap: () => Navigator.pop(context, value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: (current ?? '') == value ? JV2.navy : JV2.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (current ?? '') == value ? JV2.navy : JV2.line,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (current ?? '') == value ? Colors.white : JV2.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern(context.locale.toString());
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          SearchSubHeader(
            title: _f.launch && !_f.offer
                ? 'find.launch_units_title'.tr()
                : 'find.offers_title'.tr(),
            trailing: _total == 0
                ? null
                : 'find.n_units_total'.tr(namedArgs: {'n': nf.format(_total)}),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(kSearchPad, 12, 0, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: JV2.line)),
            ),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(end: kSearchPad),
                children: [
                  _chip(
                    'unit.offer'.tr(),
                    _f.offer,
                    () => _apply(_f.copyWith(offer: !_f.offer)),
                    key: const Key('chip-offer'),
                    close: true,
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    'unit.launch'.tr(),
                    _f.launch,
                    () => _apply(_f.copyWith(launch: !_f.launch)),
                    key: const Key('chip-launch'),
                    close: true,
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    'find.sort_discount'.tr(),
                    _f.sort == 'discount',
                    () => _apply(
                      _f.copyWith(
                        sort: _f.sort == 'discount' ? 'newest' : 'discount',
                      ),
                    ),
                    key: const Key('chip-discount'),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    _f.delivery == null
                        ? 'find.s_delivery'.tr()
                        : deliveryLabel(_f.delivery!),
                    _f.delivery != null,
                    _pickDelivery,
                    key: const Key('chip-delivery'),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    _f.maxDown == null
                        ? 'find.s_down'.tr()
                        : (_f.maxDown == '0' ? '0%' : '≤ ${_f.maxDown}%'),
                    _f.maxDown != null,
                    _pickDown,
                    key: const Key('chip-down'),
                  ),
                ],
              ),
            ),
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
                : _items.isEmpty && _loading
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(
                      kSearchPad,
                      16,
                      kSearchPad,
                      30,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [UnitCardShimmer(count: 4)],
                  )
                : _items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyBlock(
                      icon: Icons.local_offer_outlined,
                      title: 'find.offers_empty'.tr(),
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
                      for (final p in _items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: UnitCard(property: p, compact: true),
                        ),
                      if (_loading) const UnitCardShimmer(count: 1),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
