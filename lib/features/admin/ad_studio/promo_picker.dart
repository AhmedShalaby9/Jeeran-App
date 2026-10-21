import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/jv2.dart';

/// What the ad promotes: a compound or one unit.
class PromoPick {
  final String kind; // compound | unit
  final int id;
  final String name, sub;
  const PromoPick(this.kind, this.id, this.name, this.sub);
}

/// 9_800_000 → "EGP 9.8M"
String adMoney(num n) {
  if (n >= 1e6) return 'EGP ${(n / 1e6).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
  return 'EGP ${NumberFormat.decimalPattern('en').format(n.round())}';
}

typedef PromoLoader = Future<List<PromoPick>> Function(String kind, String query);

/// Default loader: compounds from /compounds, units from /properties?q=.
Future<List<PromoPick>> loadPromoOptions(String kind, String query) async {
  final c = sl<ApiClient>();
  if (kind == 'compound') {
    final res = await c.get('/compounds', queryParams: {'limit': 200}, headers: ApiClient.apiV2);
    final d = res.data['data'];
    final ar = false;
    return [
      for (final m in (d is List ? d : const []).whereType<Map<String, dynamic>>())
        PromoPick('compound', (m['id'] as num).toInt(), _name(m, ar), _compoundSub(m)),
    ];
  }
  final res = await c.get('/properties', queryParams: {'limit': 30, 'q': query}, headers: ApiClient.apiV2);
  final d = res.data['data'];
  final list = d is List ? d : (d is Map && d['items'] is List ? d['items'] as List : const []);
  return [
    for (final m in list.whereType<Map<String, dynamic>>())
      PromoPick('unit', (m['id'] as num).toInt(), '${m['title_en'] ?? m['title_ar'] ?? '#${m['id']}'}', _unitSub(m)),
  ];
}

String _name(Map<String, dynamic> m, bool ar) => '${(ar ? m['name_ar'] : m['name_en']) ?? m['name_en'] ?? m['name_ar'] ?? ''}';

String _compoundSub(Map<String, dynamic> m) {
  final n = m['units_count'] is num ? (m['units_count'] as num).toInt() : 0;
  final p = m['min_price'] is num ? m['min_price'] as num : num.tryParse('${m['min_price']}');
  if (n == 0 && p == null) return '';
  return [if (n > 0) 'adstudio.live_units'.tr(args: ['$n']), if (p != null) 'adstudio.from_price'.tr(args: [adMoney(p)])].join(' · ');
}

String _unitSub(Map<String, dynamic> m) {
  final p = num.tryParse('${m['price']}');
  final s = num.tryParse('${m['size']}');
  return [if (p != null) adMoney(p), if (s != null) '${s.round()} m²'].join(' · ');
}

/// Bottom sheet: pick a compound or a unit (a segmented control switches between them).
class PromoPickerSheet extends StatefulWidget {
  final String initialKind;
  final PromoLoader load;
  const PromoPickerSheet({super.key, this.initialKind = 'compound', required this.load});

  @override
  State<PromoPickerSheet> createState() => _PromoPickerSheetState();
}

class _PromoPickerSheetState extends State<PromoPickerSheet> {
  late String _kind = widget.initialKind;
  List<PromoPick>? _items;
  bool _failed = false;
  String? _errorMessage; // the server's own reason, when it has one — else a generic retry message
  String _q = '';
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final mine = ++_token;
    setState(() { _items = null; _failed = false; _errorMessage = null; });
    try {
      final r = await widget.load(_kind, _q.trim());
      if (mounted && mine == _token) setState(() => _items = r);
    } catch (e) {
      if (!mounted || mine != _token) return;
      final msg = e is ServerException ? e.message : null;
      setState(() { _failed = true; _errorMessage = (msg != null && msg.trim().isNotEmpty) ? msg : null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    // compounds are filtered on the phone (one list); units are searched on the server
    final list = (_items ?? []).where((p) => _kind == 'unit' || q.isEmpty || p.name.toLowerCase().contains(q)).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 38, height: 4, decoration: BoxDecoration(color: JV2.track, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: JV2.fillFaint, borderRadius: BorderRadius.circular(13)),
                child: Row(children: [
                  for (final (k, t) in [('compound', 'adstudio.k_compound'), ('unit', 'adstudio.k_unit')])
                    Expanded(
                      child: GestureDetector(
                        key: Key('promo-tab-$k'),
                        onTap: () { if (_kind != k) { _kind = k; _q = ''; _fetch(); } },
                        child: Container(
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: _kind == k ? JV2.surface : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                          child: Text(t.tr(), style: TextStyle(fontSize: 12.5, fontWeight: _kind == k ? FontWeight.w700 : FontWeight.w500, color: _kind == k ? JV2.ink : JV2.inkSub)),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: const Key('promo-search'),
                onChanged: (v) { _q = v; if (_kind == 'unit') { _fetch(); } else { setState(() {}); } },
                decoration: InputDecoration(hintText: 'adstudio.search'.tr(), prefixIcon: const Icon(Icons.search_rounded)),
              ),
            ),
            Expanded(
              child: _failed
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_errorMessage ?? 'adstudio.load_failed'.tr(), textAlign: TextAlign.center, key: const Key('promo-load-failed')),
                        const SizedBox(height: 10),
                        FilledButton(key: const Key('promo-load-retry'), onPressed: _fetch, child: Text('adstudio.retry'.tr())),
                      ]),
                    )
                  : _items == null
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                          ? Center(child: Text('adstudio.nothing_found'.tr(), style: const TextStyle(color: JV2.inkSub)))
                          : ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (_, i) => ListTile(
                                key: Key('promo-${list[i].kind}-${list[i].id}'),
                                title: Text(list[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: list[i].sub.isEmpty ? null : Text(list[i].sub),
                                onTap: () => Navigator.pop(context, list[i]),
                              ),
                            ),
            ),
          ]),
        ),
      ),
    );
  }
}
