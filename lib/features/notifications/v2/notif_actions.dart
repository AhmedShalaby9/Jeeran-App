import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/jv2.dart';
import '../../ai_ads/presentation/pages/ai_ads_page.dart';
import '../../compounds/presentation/pages/compound_page.dart';
import '../../developers/presentation/pages/developer_page.dart';
import '../../news/v2/news_list_page.dart';
import '../../news/v2/news_article_page.dart';
import '../../packages/presentation/pages/packages_destination.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/presentation/pages/property_details_page.dart';
import 'notif_api.dart';

/// What a notification row offers as its call to action, and where it goes.
class NotifAction {
  final String labelKey;
  final void Function(BuildContext context) run;
  const NotifAction(this.labelKey, this.run);
}

/// The CTA for a row, from what the notification is about. The English title identifies the
/// rejection message: it is stored in English whatever language the user reads.
NotifAction? actionFor(InboxItem n, {required bool ar}) {
  final id = n.entityId;
  switch (n.type) {
    case 'property':
      if (id == null) return null;
      if (n.titleEn == 'Property Rejected') {
        return NotifAction(
          'notif.a_read_reason',
          (c) => _showReason(c, n.body(ar)),
        );
      }
      return NotifAction(
        'notif.a_view_listing',
        (c) => openPropertyById(c, id),
      );
    case 'project':
      if (id == null) return null;
      return NotifAction(
        'notif.a_see_units',
        (c) => _push(c, CompoundPage(compoundId: id)),
      );
    case 'developer':
      if (id == null) return null;
      return NotifAction(
        'notif.a_view_developer',
        (c) => _push(c, DeveloperPage(developerId: id)),
      );
    case 'subscription':
      return NotifAction(
        'notif.a_upgrade',
        (c) => _push(c, const PackagesDestination()),
      );
    case 'news':
      return NotifAction(
        'notif.a_open_news',
        (c) => _push(
          c,
          id == null ? const NewsListPage() : NewsArticlePage(id: id),
        ),
      );
    case 'ad':
      return NotifAction('notif.a_open_ad', (c) => _push(c, const AiAdsPage()));
    default:
      return null;
  }
}

void _push(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));

Future<void> openPropertyById(BuildContext context, int id) async {
  try {
    final res = await sl<ApiClient>().get('/properties/$id');
    final data = res.data['data'];
    if (data is! Map<String, dynamic> || !context.mounted) return;
    _push(context, PropertyDetailsPage(property: PropertyModel.fromJson(data)));
  } catch (_) {}
}

void _showReason(BuildContext context, String reason) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x570B2A4A),
    builder: (_) => Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: JV2.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: JV2.track,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('notif.reason_title'.tr(), style: JV2.display(context, 22)),
          const SizedBox(height: 10),
          Text(reason, style: JV2.sub),
        ],
      ),
    ),
  );
}
