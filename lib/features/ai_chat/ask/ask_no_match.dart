import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/jv2.dart';
import 'ask_api.dart';

/// A saved search as a few readable chips (type, sale/rent, place, bedrooms, budget).
List<String> noMatchChips(Map<String, dynamic> f, Map<String, String> n, bool ar) {
  String? s(String k) => f[k] is String && (f[k] as String).isNotEmpty ? f[k] as String : null;
  num? num_(String k) => f[k] is num ? f[k] as num : null;
  String money(num v) => v >= 1e6 ? '${(v / 1e6).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')}M' : '${(v / 1000).round()}K';
  final out = <String>[];
  final type = s('property_type');
  if (type != null) out.add('type.$type'.tr());
  final status = s('property_status');
  if (status != null) out.add('status.$status'.tr());
  final lt = s('listing_type');
  if (lt != null) out.add(lt == 'primary' ? 'concierge.nm_primary'.tr() : 'concierge.nm_resale'.tr());
  final compound = ar ? (n['compound_ar'] ?? n['compound_en']) : (n['compound_en'] ?? n['compound_ar']);
  if (compound != null) out.add(compound);
  final dev = ar ? (n['developer_ar'] ?? n['developer_en']) : (n['developer_en'] ?? n['developer_ar']);
  if (dev != null) out.add(dev);
  final st = s('state');
  if (st != null) out.add('location.state.$st'.tr());
  final beds = num_('bedrooms');
  if (beds != null) out.add('concierge.nm_beds'.tr(namedArgs: {'n': '${beds.toInt()}'}));
  final baths = num_('bathrooms');
  if (baths != null) out.add('concierge.nm_baths'.tr(namedArgs: {'n': '${baths.toInt()}'}));
  final lo = num_('min_price');
  final hi = num_('max_price');
  if (lo != null && hi != null) {
    out.add('${money(lo)}–${money(hi)}');
  } else if (hi != null) {
    out.add('concierge.nm_up_to'.tr(namedArgs: {'v': money(hi)}));
  } else if (lo != null) {
    out.add('concierge.nm_from'.tr(namedArgs: {'v': money(lo)}));
  }
  final q = s('q');
  if (q != null) out.add('“$q”');
  return out;
}

/// "Nothing matches yet": what the person asked for, and a way to be told when something fits.
/// Notify me saves the search (`POST /saved-requests`); the server tells them when a unit that fits goes live.
class AskNoMatchCard extends StatefulWidget {
  final AskNoMatch data;
  final Future<void> Function(AskNoMatch data, String lang)? save; // tests inject a fake
  const AskNoMatchCard({super.key, required this.data, this.save});

  @override
  State<AskNoMatchCard> createState() => _AskNoMatchCardState();
}

enum _Stage { idle, saving, saved, dismissed }

class _AskNoMatchCardState extends State<AskNoMatchCard> {
  _Stage _stage = _Stage.idle;
  bool _failed = false;

  Future<void> _post(AskNoMatch d, String lang) => sl<ApiClient>().post(
    ApiEndpoints.savedRequests,
    data: {'filters': d.filters, 'original_text': d.text, 'lang': lang},
  );

  Future<void> _notify() async {
    if (_stage == _Stage.saving || _stage == _Stage.saved) return;
    if (widget.save == null && !AppStorage.isLoggedIn) {
      AppSnackbar.show(context, message: 'concierge.nm_sign_in'.tr(), icon: Icons.info_outline_rounded, iconColor: JV2.gold);
      return;
    }
    setState(() {
      _stage = _Stage.saving;
      _failed = false;
    });
    try {
      await (widget.save ?? _post)(widget.data, context.locale.languageCode);
      if (mounted) setState(() => _stage = _Stage.saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _stage = _Stage.idle;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _Stage.dismissed) return const SizedBox.shrink();
    final ar = context.locale.languageCode == 'ar';
    final saved = _stage == _Stage.saved;
    final chips = noMatchChips(widget.data.filters, widget.data.names, ar);
    return Container(
      key: const Key('ask-no-match'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: saved ? JV2.fillFaint : JV2.goldFilm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: saved ? JV2.line : JV2.goldEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(saved ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, size: 18, color: JV2.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  saved ? 'concierge.nm_saved_title'.tr() : 'concierge.nm_title'.tr(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: JV2.ink),
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: JV2.line)),
                    child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: JV2.inkSub)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            saved ? 'concierge.nm_saved_body'.tr() : (_failed ? 'concierge.nm_failed'.tr() : 'concierge.nm_body'.tr()),
            style: TextStyle(fontSize: 12.5, height: 1.4, color: _failed ? JV2.danger : JV2.inkSub),
          ),
          if (!saved) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: JV2PrimaryButton(
                    key: const Key('ask-no-match-notify'),
                    height: 44,
                    onPressed: _stage == _Stage.saving ? null : _notify,
                    child: _stage == _Stage.saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('concierge.nm_notify'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: const Key('ask-no-match-skip'),
                  onPressed: _stage == _Stage.saving ? null : () => setState(() => _stage = _Stage.dismissed),
                  child: Text('concierge.nm_skip'.tr(), style: const TextStyle(color: JV2.inkSub, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
