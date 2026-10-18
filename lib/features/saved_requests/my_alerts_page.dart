import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/widgets/jv2.dart';
import '../ai_chat/ask/ask_no_match.dart';

/// One search the person asked to be told about.
class SavedAlert {
  final int id;
  final String text;
  final Map<String, dynamic> filters;
  final Map<String, String> names;
  final DateTime createdAt;
  const SavedAlert(this.id, this.text, this.filters, this.names, this.createdAt);

  factory SavedAlert.fromJson(Map<String, dynamic> j) {
    final n = j['names'] is Map ? Map<String, dynamic>.from(j['names'] as Map) : const <String, dynamic>{};
    return SavedAlert(
      (j['id'] as num).toInt(),
      (j['original_text'] is String ? j['original_text'] as String : '').trim(),
      j['filters'] is Map ? Map<String, dynamic>.from(j['filters'] as Map) : const {},
      {for (final e in n.entries) if (e.value is String && (e.value as String).isNotEmpty) e.key: e.value as String},
      DateTime.tryParse('${j['created_at']}')?.toLocal() ?? DateTime.now(),
    );
  }
}

/// "My alerts": the searches Jeeran will tell the person about when a matching unit is listed. Each can be stopped.
class MyAlertsPage extends StatefulWidget {
  final Future<List<SavedAlert>> Function()? load; // tests inject a fake
  final Future<void> Function(int id)? cancel; // tests inject a fake
  const MyAlertsPage({super.key, this.load, this.cancel});

  @override
  State<MyAlertsPage> createState() => _MyAlertsPageState();
}

class _MyAlertsPageState extends State<MyAlertsPage> {
  List<SavedAlert>? _items;
  bool _failed = false;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<List<SavedAlert>> _load() async {
    final res = await sl<ApiClient>().get(ApiEndpoints.savedRequests);
    final d = res.data['data'];
    return [for (final m in (d is List ? d : const []).whereType<Map<String, dynamic>>()) SavedAlert.fromJson(m)];
  }

  Future<void> _cancel(int id) => sl<ApiClient>().delete('${ApiEndpoints.savedRequests}/$id');

  Future<void> _fetch() async {
    setState(() => _failed = false);
    try {
      final items = await (widget.load ?? _load)();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _stop(SavedAlert a) async {
    if (_busy.contains(a.id)) return;
    setState(() => _busy.add(a.id));
    try {
      await (widget.cancel ?? _cancel)(a.id);
      if (mounted) setState(() => _items = _items!.where((x) => x.id != a.id).toList());
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('alerts.stop_failed'.tr())));
    } finally {
      if (mounted) setState(() => _busy.remove(a.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final items = _items;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      appBar: AppBar(
        backgroundColor: JV2.bgDeep,
        elevation: 0,
        foregroundColor: JV2.ink,
        title: Text('alerts.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: _failed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('alerts.load_failed'.tr()),
                  const SizedBox(height: 12),
                  JV2PrimaryButton(width: 160, height: 44, onPressed: _fetch, child: Text('explore.try_again'.tr())),
                ],
              ),
            )
          : items == null
              ? const Center(child: CircularProgressIndicator(color: JV2.gold))
              : items.isEmpty
                  ? Center(
                      key: const Key('alerts-empty'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text('alerts.empty'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: JV2.inkSub, height: 1.5)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final a = items[i];
                        final chips = noMatchChips(a.filters, a.names, ar);
                        return Container(
                          key: Key('alert-${a.id}'),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: JV2.line)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (a.text.isNotEmpty) Text(a.text, style: const TextStyle(fontWeight: FontWeight.w700, color: JV2.ink)),
                              if (chips.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final c in chips)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: JV2.fillFaint, borderRadius: BorderRadius.circular(999)),
                                        child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: JV2.inkSub)),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'alerts.since'.tr(args: [DateFormat.yMMMd(context.locale.toString()).format(a.createdAt)]),
                                      style: const TextStyle(fontSize: 12, color: JV2.inkMute),
                                    ),
                                  ),
                                  TextButton(
                                    key: Key('alert-stop-${a.id}'),
                                    onPressed: _busy.contains(a.id) ? null : () => _stop(a),
                                    child: Text('alerts.stop'.tr(), style: const TextStyle(color: JV2.danger, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
