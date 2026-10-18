import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../notifications/v2/notif_actions.dart' show openPropertyById;

String? _s(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

/// One "Request a call" from the app: a buyer asked Jeeran to call them about a primary unit.
class CallRequestRow {
  final int id;
  final String status; // new | contacted | closed
  final String? name, phone, email, unitTitle, reference, note;
  final bool phoneVerified;
  final int? propertyId;
  final num? price;
  final DateTime createdAt;

  const CallRequestRow({
    required this.id,
    required this.status,
    this.name,
    this.phone,
    this.email,
    this.unitTitle,
    this.reference,
    this.note,
    this.phoneVerified = true,
    this.propertyId,
    this.price,
    required this.createdAt,
  });

  factory CallRequestRow.fromJson(Map<String, dynamic> j) {
    final u = j['user'] is Map ? Map<String, dynamic>.from(j['user'] as Map) : const <String, dynamic>{};
    return CallRequestRow(
      id: (j['id'] as num).toInt(),
      status: _s(j['status']) ?? 'new',
      name: _s(u['name']),
      // the number the buyer asked to be called on, else the one on their account
      phone: _s(j['contact_phone']) ?? _s(u['phone']),
      email: _s(u['email']),
      unitTitle: _s(j['property_title']),
      reference: _s(j['reference_code']),
      note: _s(j['admin_note']),
      phoneVerified: j['phone_verified'] != false,
      propertyId: j['property_id'] is num ? (j['property_id'] as num).toInt() : null,
      price: j['price'] == null ? null : num.tryParse('${j['price']}'),
      createdAt: DateTime.tryParse('${j['created_at']}')?.toLocal() ?? DateTime.now(),
    );
  }

  CallRequestRow copy({String? status, String? note}) => CallRequestRow(
    id: id,
    status: status ?? this.status,
    name: name,
    phone: phone,
    email: email,
    unitTitle: unitTitle,
    reference: reference,
    note: note ?? this.note,
    phoneVerified: phoneVerified,
    propertyId: propertyId,
    price: price,
    createdAt: createdAt,
  );
}

/// Call requests for admins: who asked, about which unit, call or WhatsApp them, and mark it contacted / closed.
class AdminCallRequestsPage extends StatefulWidget {
  final Future<List<CallRequestRow>> Function(String status)? load; // tests inject a fake
  final Future<Map<String, int>> Function()? counts; // tests inject a fake
  final Future<void> Function(int id, {String? status, String? note})? update; // tests inject a fake
  const AdminCallRequestsPage({super.key, this.load, this.counts, this.update});

  @override
  State<AdminCallRequestsPage> createState() => _AdminCallRequestsPageState();
}

class _AdminCallRequestsPageState extends State<AdminCallRequestsPage> with SingleTickerProviderStateMixin {
  static const _tabs = ['new', 'contacted', 'closed', ''];
  late final TabController _tab = TabController(length: _tabs.length, vsync: this)
    ..addListener(() {
      if (!_tab.indexIsChanging) _fetch();
    });
  List<CallRequestRow>? _items;
  Map<String, int> _counts = const {};
  bool _failed = false;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<List<CallRequestRow>> _load(String status) async {
    final res = await sl<ApiClient>().get(ApiEndpoints.callRequests, queryParams: {if (status.isNotEmpty) 'status': status, 'limit': 100});
    final d = res.data['data'];
    return [for (final m in (d is List ? d : const []).whereType<Map<String, dynamic>>()) CallRequestRow.fromJson(m)];
  }

  Future<Map<String, int>> _loadCounts() async {
    final res = await sl<ApiClient>().get('${ApiEndpoints.callRequests}/counts');
    final d = res.data['data'];
    return {for (final e in (d is Map ? d : const {}).entries) '${e.key}': (e.value as num).toInt()};
  }

  Future<void> _update(int id, {String? status, String? note}) async {
    await sl<ApiClient>().put('${ApiEndpoints.callRequests}/$id', data: {'status': ?status, 'admin_note': ?note});
  }

  Future<void> _fetch() async {
    final status = _tabs[_tab.index];
    setState(() => _failed = false);
    try {
      final items = await (widget.load ?? _load)(status);
      final counts = await (widget.counts ?? _loadCounts)().catchError((_) => _counts);
      if (!mounted || _tabs[_tab.index] != status) return;
      setState(() {
        _items = items;
        _counts = counts;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _change(CallRequestRow r, {String? status, String? note}) async {
    if (_busy.contains(r.id)) return;
    setState(() => _busy.add(r.id));
    try {
      await (widget.update ?? _update)(r.id, status: status, note: note);
      if (!mounted) return;
      final tab = _tabs[_tab.index];
      setState(() {
        final next = r.copy(status: status, note: note);
        // a request that no longer belongs on this tab leaves it
        _items = [
          for (final x in _items!)
            if (x.id != r.id) x else if (tab.isEmpty || tab == next.status) next,
        ];
      });
      final counts = await (widget.counts ?? _loadCounts)().catchError((_) => _counts);
      if (mounted) setState(() => _counts = counts);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.action_failed'.tr())));
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  Future<void> _call(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isNotEmpty) await launchUrl(Uri(scheme: 'tel', path: cleaned));
  }

  Future<void> _whatsapp(String number) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) await launchUrl(Uri.parse('https://wa.me/$digits'), mode: LaunchMode.externalApplication);
  }

  Future<void> _editNote(CallRequestRow r) async {
    final ctrl = TextEditingController(text: r.note ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('admin.cr_note'.tr()),
        content: TextField(key: const Key('cr-note-field'), controller: ctrl, maxLines: 4, autofocus: true, decoration: InputDecoration(hintText: 'admin.cr_note_hint'.tr())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('actions.cancel'.tr())),
          TextButton(key: const Key('cr-note-save'), onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text('admin.cr_save'.tr())),
        ],
      ),
    );
    if (saved != null && saved != (r.note ?? '')) _change(r, note: saved);
  }

  String _tabLabel(String key) => key.isEmpty ? 'admin.cr_all'.tr() : 'admin.cr_$key'.tr();

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('admin.call_requests'.tr()),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            for (final t in _tabs)
              Tab(text: '${_tabLabel(t)}${(_counts[t.isEmpty ? 'all' : t] ?? 0) > 0 ? ' (${_counts[t.isEmpty ? 'all' : t]})' : ''}'),
          ],
        ),
      ),
      body: _failed
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('admin.load_failed'.tr(), style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _fetch, child: Text('actions.retry'.tr())),
              ]),
            )
          : items == null
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? Center(key: const Key('cr-empty'), child: Text('admin.cr_empty'.tr()))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _tile(items[i]),
                      ),
                    ),
    );
  }

  Widget _tile(CallRequestRow r) {
    final busy = _busy.contains(r.id);
    final phone = r.phone;
    return Container(
      key: Key('cr-${r.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(r.name ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink))),
            _StatusPill(r.status),
          ]),
          if (phone != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Text(phone, textDirection: ui.TextDirection.ltr, style: const TextStyle(fontSize: 13.5, color: AppColors.secondary, fontWeight: FontWeight.w600)),
              if (!r.phoneVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(999)),
                  child: Text('admin.cr_unverified'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                ),
              ],
            ]),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: r.propertyId == null ? null : () => openPropertyById(context, r.propertyId!),
            child: Text(
              r.unitTitle ?? 'admin.cr_unit'.tr(args: ['${r.propertyId ?? ''}']),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink, decoration: TextDecoration.underline),
            ),
          ),
          Text(
            [
              if (r.reference != null) r.reference!,
              if (r.price != null) 'EGP ${NumberFormat.decimalPattern().format(r.price)}',
              DateFormat.yMMMd(context.locale.toString()).add_jm().format(r.createdAt),
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: AppColors.inkMute),
          ),
          if (r.note != null) ...[
            const SizedBox(height: 6),
            Text(r.note!, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSub, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (phone != null) _Btn(key: Key('cr-call-${r.id}'), icon: Icons.call_outlined, label: 'admin.cr_call'.tr(), onTap: () => _call(phone)),
            if (phone != null) _Btn(key: Key('cr-wa-${r.id}'), icon: Icons.chat_outlined, label: 'WhatsApp', onTap: () => _whatsapp(phone)),
            _Btn(key: Key('cr-note-${r.id}'), icon: Icons.edit_note_rounded, label: 'admin.cr_note'.tr(), onTap: busy ? null : () => _editNote(r)),
            if (r.status == 'new') _Btn(key: Key('cr-contacted-${r.id}'), icon: Icons.check_rounded, label: 'admin.cr_mark_contacted'.tr(), onTap: busy ? null : () => _change(r, status: 'contacted')),
            if (r.status != 'closed') _Btn(key: Key('cr-close-${r.id}'), icon: Icons.done_all_rounded, label: 'admin.cr_mark_closed'.tr(), onTap: busy ? null : () => _change(r, status: 'closed')),
            if (r.status == 'closed') _Btn(key: Key('cr-reopen-${r.id}'), icon: Icons.refresh_rounded, label: 'admin.cr_reopen'.tr(), onTap: busy ? null : () => _change(r, status: 'new')),
          ]),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'contacted' => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      'closed' => (const Color(0xFFE5E7EB), const Color(0xFF4B5563)),
      _ => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text('admin.cr_$status'.tr(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Btn({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.ink,
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: const Size(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
