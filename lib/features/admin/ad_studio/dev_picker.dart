import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/jv2.dart';

/// A developer in the picker.
class DevRef {
  final int id;
  final String nameAr, nameEn;
  final String? logo;
  final int compounds, units;
  const DevRef(this.id, this.nameAr, this.nameEn, {this.logo, this.compounds = 0, this.units = 0});
  String name(bool ar) => ar ? (nameAr.isNotEmpty ? nameAr : nameEn) : (nameEn.isNotEmpty ? nameEn : nameAr);
  factory DevRef.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    final logo = j['logo'];
    return DevRef(
      (j['id'] as num).toInt(),
      '${j['name_ar'] ?? ''}',
      '${j['name_en'] ?? ''}',
      logo: logo is String && logo.isNotEmpty ? logo : null,
      compounds: n(j['compounds_count'] ?? j['projects_count']), // the v1 API calls compounds "projects"
      units: n(j['units_count']),
    );
  }

  String get initials {
    final parts = nameEn.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return nameAr.isEmpty ? '?' : nameAr.characters.first;
    return parts.take(2).map((w) => w.characters.first.toUpperCase()).join();
  }
}

/// Every developer, just id and names (the light list the studio's pickers use).
Future<List<DevRef>> loadDevelopers() async {
  final res = await sl<ApiClient>().get('/developers', queryParams: {'brief': 'true'});
  final d = res.data['data'];
  return [for (final m in (d is List ? d : const []).whereType<Map<String, dynamic>>()) DevRef.fromJson(m)];
}

class DevPickerSheet extends StatefulWidget {
  final Future<List<DevRef>> Function() load;
  final bool ar;
  const DevPickerSheet({required this.load, required this.ar});

  @override
  State<DevPickerSheet> createState() => _DevPickerSheetState();
}

class _DevPickerSheetState extends State<DevPickerSheet> {
  List<DevRef>? _all;
  bool _failed = false;
  String? _errorMessage; // the server's own reason, when it has one — else a generic retry message
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() { _all = null; _failed = false; _errorMessage = null; });
    widget.load().then((l) { if (mounted) setState(() => _all = l); }).catchError((e) {
      if (!mounted) return;
      final msg = e is ServerException ? e.message : null;
      setState(() { _failed = true; _errorMessage = (msg != null && msg.trim().isNotEmpty) ? msg : null; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = (_all ?? []).where((d) => q.isEmpty || '${d.nameAr} ${d.nameEn}'.toLowerCase().contains(q)).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 38, height: 4, decoration: BoxDecoration(color: JV2.track, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(key: const Key('dev-search'), onChanged: (v) => setState(() => _q = v), decoration: InputDecoration(hintText: 'adstudio.search_dev'.tr(), prefixIcon: const Icon(Icons.search_rounded))),
            ),
            Expanded(
              child: _failed
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_errorMessage ?? 'adstudio.load_failed'.tr(), textAlign: TextAlign.center, key: const Key('dev-load-failed')),
                        const SizedBox(height: 10),
                        FilledButton(key: const Key('dev-load-retry'), onPressed: _load, child: Text('adstudio.retry'.tr())),
                      ]),
                    )
                  : _all == null
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) => ListTile(key: Key('dev-${list[i].id}'), title: Text(list[i].name(widget.ar)), onTap: () => Navigator.pop(context, list[i])),
                        ),
            ),
          ]),
        ),
      ),
    );
  }
}
