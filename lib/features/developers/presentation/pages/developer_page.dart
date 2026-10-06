import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../../follow/data/follow_service.dart';
import '../../../follow/presentation/follow_pill.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/pages/project_details_page.dart';

/// A developer's page: who they are, whether they're verified, their compounds,
/// and a Follow button. (The full v2 developer page — tabs, alerts, messages — comes later.)
class DeveloperPage extends StatefulWidget {
  final int developerId;
  final String? name; // shown while loading

  const DeveloperPage({super.key, required this.developerId, this.name});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  Map<String, dynamic>? _dev;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final res = await sl<ApiClient>().get(ApiEndpoints.developerById(widget.developerId));
      final data = res.data['data'];
      if (data is Map<String, dynamic>) {
        if (mounted) setState(() => _dev = data);
        return;
      }
      throw Exception();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  String _pick(String key) {
    final ar = (_dev?['${key}_ar'] as String?) ?? '';
    final en = (_dev?['${key}_en'] as String?) ?? '';
    return isArabic(context) ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
  }

  Future<void> _open(String? raw, {String scheme = ''}) async {
    if (raw == null || raw.isEmpty) return;
    final uri = scheme.isEmpty
        ? Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw')
        : Uri(scheme: scheme, path: raw);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final dev = _dev;
    final name = dev == null ? (widget.name ?? '') : _pick('name');
    final verified = dev?['is_verified'] == true;
    final projects = dev == null
        ? <ProjectModel>[]
        : ((dev['projects'] as List?) ?? const [])
              .whereType<Map<String, dynamic>>()
              .where((p) => p['is_active'] != false)
              .map((p) => ProjectModel.fromJson({...p, 'developer': dev}))
              .toList();
    final desc = _pick('desc');
    final followers = (dev?['followers_count'] as num?)?.toInt() ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: JV2.bgDeep,
        body: JV2Ambient(
          intensity: 0.7,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 8),
                child: const Align(alignment: AlignmentDirectional.centerStart, child: JV2BackButton()),
              ),
              Expanded(
                child: _failed
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('explore.load_failed'.tr(), style: JV2.display(context, 22)),
                            const SizedBox(height: 16),
                            JV2PrimaryButton(width: 160, height: 46, onPressed: _load, child: Text('explore.try_again'.tr())),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: JV2.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: JV2.line),
                                ),
                                child: ((dev?['logo'] as String?) ?? '').isNotEmpty
                                    ? Photo(url: dev!['logo'] as String, width: 64, height: 64, radius: 18)
                                    : Text(
                                        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                                        style: JV2.display(context, 26).copyWith(color: JV2.navy),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: JV2.display(context, 26)),
                                    if (verified) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.verified_user_outlined, size: 14, color: JV2.success),
                                          const SizedBox(width: 5),
                                          Text(
                                            'developer.verified'.tr(),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: JV2.success),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (dev != null)
                            Row(
                              children: [
                                FollowButton(type: FollowType.developer, id: widget.developerId),
                                const SizedBox(width: 12),
                                Text(
                                  'developer.followers'.plural(followers),
                                  style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
                                ),
                              ],
                            ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(desc, style: JV2.sub),
                          ],
                          if (dev != null && ((dev['phone'] as String?) ?? '').isNotEmpty ||
                              ((dev?['website'] as String?) ?? '').isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              children: [
                                if (((dev?['phone'] as String?) ?? '').isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(Icons.call_outlined, size: 16, color: JV2.navy),
                                    label: Text(dev!['phone'] as String),
                                    onPressed: () => _open(dev['phone'] as String, scheme: 'tel'),
                                  ),
                                if (((dev?['website'] as String?) ?? '').isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(Icons.language_rounded, size: 16, color: JV2.navy),
                                    label: Text('developer.website'.tr()),
                                    onPressed: () => _open(dev!['website'] as String),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 26),
                          if (projects.isNotEmpty) ...[
                            Text(
                              'developer.compounds'.tr().toUpperCase(),
                              style: JV2.eyebrow.copyWith(fontSize: 10, letterSpacing: 1.8),
                            ),
                            const SizedBox(height: 12),
                            for (final p in projects)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ProjectDetailsPage(project: p)),
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
                                        Photo(url: p.coverImage, width: 64, height: 64, radius: 12),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            isArabic(context) && p.nameAr.isNotEmpty ? p.nameAr : p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: JV2.ink),
                                          ),
                                        ),
                                        Icon(chevronIcon(context), size: 18, color: JV2.inkMute),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          if (dev == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(child: CircularProgressIndicator(color: JV2.navy)),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
