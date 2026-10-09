import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/jv2.dart';
import '../voice/voice_api.dart';
import '../voice/voice_services.dart';
import '../../core/storage/app_storage.dart';
import 'alert_shortcut_page.dart';
import 'listing_api.dart';
import 'price_alert_api.dart';
import 'listing_flow.dart';
import 'listing_widgets.dart';
import 'price_shortcut_page.dart';

/// "Do it": pick what to hand to Jeeran. Each shortcut shows exactly what it is about to do before it does it.
class ShortcutHub extends StatelessWidget {
  final ListingApi? api;
  final PriceAlertApi? priceAlertApi;

  /// Who may list and re-price; defaults to the signed-in user's role (tests set it).
  final bool? canList;
  final VoiceRecorder? recorder;
  final VoiceApi? voiceApi;
  const ShortcutHub({
    super.key,
    this.api,
    this.priceAlertApi,
    this.canList,
    this.recorder,
    this.voiceApi,
  });

  static Future<void> open(BuildContext context) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const ShortcutHub(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final a = api ?? ListingApi(sl<ApiClient>());

    Widget tile(String key, String title, String sub, VoidCallback onTap) =>
        GestureDetector(
          key: Key(key),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
            decoration: BoxDecoration(
              color: JV2.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: JV2.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: JV2.inkSub,
                  ),
                ),
              ],
            ),
          ),
        );

    final canList = this.canList ?? (AppStorage.isSeller || AppStorage.isAdmin);
    final alertApi = priceAlertApi ?? PriceAlertApi(sl<ApiClient>());
    final tiles = <Widget>[
      if (canList)
        tile(
          'tile-list',
          'listing.hub_list'.tr(),
          'listing.hub_list_sub'.tr(),
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => ListingFlow(
                api: api,
                recorder: recorder,
                voiceApi: voiceApi,
                initialView: ListingView.assistant,
              ),
            ),
          ),
        ),
      if (canList)
        tile(
          'tile-price',
          'listing.hub_price'.tr(),
          'listing.hub_price_sub'.tr(),
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => PriceShortcutPage(
                api: a,
                recorder: recorder,
                voiceApi: voiceApi,
              ),
            ),
          ),
        ),
      tile(
        'tile-alert',
        'listing.hub_alert'.tr(),
        'listing.hub_alert_sub'.tr(),
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => AlertShortcutPage(
              api: alertApi,
              recorder: recorder,
              voiceApi: voiceApi,
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(kListPad, top + 8, kListPad, 12),
            decoration: const BoxDecoration(
              color: Color(0xF0FAFBFD),
              border: Border(bottom: BorderSide(color: JV2.line)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: JV2.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: JV2.line),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: JV2.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [JV2.navyLift, JV2.navy],
                    ),
                  ),
                  child: const Center(
                    child: SparkIcon(size: 14, color: Color(0xFFE5C48F)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'listing.hub_header'.tr(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                      Text(
                        'listing.ai_header_sub'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: JV2.inkSub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(kListPad, 24, kListPad, 24),
              children: [
                Text('listing.hub_title'.tr(), style: JV2.display(context, 27)),
                const SizedBox(height: 12),
                Text('listing.hub_sub'.tr(), style: JV2.sub),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final t in tiles)
                      SizedBox(
                        width:
                            (MediaQuery.sizeOf(context).width -
                                kListPad * 2 -
                                9) /
                            2,
                        child: t,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
