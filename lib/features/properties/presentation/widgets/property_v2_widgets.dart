import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/jv2.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';

const double kPropPad = 20;

String money(BuildContext context, num? v) => v == null
    ? '—'
    : NumberFormat.decimalPattern(context.locale.toString()).format(v.round());

/// Small caps label above a block.
class PropLabel extends StatelessWidget {
  final String text;
  const PropLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 9),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: JV2.inkSub,
      ),
    ),
  );
}

/// A white rounded block.
class PropCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const PropCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: JV2.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: JV2.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0B2A4A),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

/// One gallery slot: a photo, the walkthrough video, or the floor plan.
class PropMedia {
  final String kind; // image | video | plan
  final String? url; // photo / plan url; for video the poster
  const PropMedia(this.kind, this.url);
}

class PropGallery extends StatelessWidget {
  final List<PropMedia> media;
  final int index;
  final PageController controller;
  final bool featured;
  final bool saved;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onTapMedia;
  final VoidCallback onSave;

  const PropGallery({
    super.key,
    required this.media,
    required this.index,
    required this.controller,
    required this.featured,
    required this.saved,
    required this.onPage,
    required this.onTapMedia,
    required this.onSave,
  });

  Widget _glass(Widget child, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xEBFFFFFF),
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x290B2A4A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 306,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media.isEmpty)
            const Photo(radius: 0)
          else
            PageView.builder(
              controller: controller,
              itemCount: media.length,
              onPageChanged: onPage,
              itemBuilder: (_, i) {
                final m = media[i];
                return GestureDetector(
                  onTap: () => onTapMedia(i),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Photo(url: m.url, radius: 0),
                      if (m.kind == 'plan')
                        Container(color: const Color(0xCCFFFFFF)),
                      if (m.kind == 'plan' && m.url != null)
                        Padding(
                          padding: const EdgeInsets.all(26),
                          child: Image.network(
                            m.url!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      if (m.kind == 'video')
                        Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xCCFFFFFF),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 30,
                              color: JV2.navy,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x570B2A4A),
                    Color(0x000B2A4A),
                    Color(0x000B2A4A),
                    Color(0x660B2A4A),
                  ],
                  stops: [0, 0.3, 0.66, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: kPropPad,
            right: kPropPad,
            child: Row(
              children: [
                _glass(
                  Icon(
                    isRtl(context)
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 24,
                    color: JV2.ink,
                  ),
                  () => Navigator.maybePop(context),
                ),
                const Spacer(),
                _glass(
                  Icon(
                    saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: saved ? JV2.gold : JV2.ink,
                  ),
                  onSave,
                ),
              ],
            ),
          ),
          if (featured)
            PositionedDirectional(
              start: kPropPad,
              top: top + 62,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [JV2.goldHi, JV2.gold],
                  ),
                ),
                child: Text(
                  'explore.featured'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (media.length > 1)
            Positioned(
              left: kPropPad,
              right: kPropPad,
              bottom: 12,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    for (var i = 0; i < media.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        flex: i == index ? 24 : 10,
                        child: GestureDetector(
                          onTap: () => controller.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                          ),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: i == index
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Photo(url: media[i].url, radius: 0),
                                if (media[i].kind == 'video')
                                  Container(
                                    color: const Color(0x570B2A4A),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (media[i].kind == 'plan')
                                  Container(
                                    color: const Color(0xB8FFFFFF),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'prop.plan'.tr(),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        color: JV2.navy,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Beds / baths / built / garden in one strip.
class KeyFacts extends StatelessWidget {
  final List<(IconData icon, String value, String label)> items;
  const KeyFacts(this.items, {super.key});

  @override
  Widget build(BuildContext context) => PropCard(
    child: IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const VerticalDivider(width: 1, thickness: 1, color: JV2.line),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 4,
                ),
                child: Column(
                  children: [
                    Icon(items[i].$1, size: 19, color: JV2.navy),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$2,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: JV2.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: JV2.inkMute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class StatusChips extends StatelessWidget {
  final List<(String text, bool good)> chips;
  const StatusChips(this.chips, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: kPropPad),
      itemCount: chips.length,
      separatorBuilder: (_, _) => const SizedBox(width: 7),
      itemBuilder: (_, i) {
        final (text, good) = chips[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: good ? const Color(0x17137A55) : JV2.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: good ? const Color(0x47137A55) : JV2.line,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: good ? JV2.success : JV2.inkSub,
            ),
          ),
        );
      },
    ),
  );
}

/// "Compound" or "Developer" row in the chain up from the unit.
class ChainRow extends StatelessWidget {
  final String eyebrow;
  final Widget leading;
  final String title;
  final bool verified;
  final String sub;
  final VoidCallback onTap;
  const ChainRow({
    super.key,
    required this.eyebrow,
    required this.leading,
    required this.title,
    required this.sub,
    required this.onTap,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: PropCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: JV2.gold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 13,
                        color: JV2.success,
                      ),
                    ],
                  ],
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 11.5, color: JV2.inkMute),
                  ),
                ],
              ],
            ),
          ),
          Icon(chevronIcon(context), size: 15, color: JV2.inkMute),
        ],
      ),
    ),
  );
}

/// Label ……… value table.
class FactsTable extends StatelessWidget {
  final List<(String, String)> rows;
  const FactsTable(this.rows, {super.key});

  @override
  Widget build(BuildContext context) => PropCard(
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : const Border(top: BorderSide(color: JV2.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rows[i].$1,
                  style: const TextStyle(fontSize: 13, color: JV2.inkSub),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

IconData amenityIcon(String key) => switch (key) {
  'sea_view' => Icons.water_rounded,
  'pool_view' => Icons.pool_rounded,
  'private_garden' => Icons.yard_rounded,
  'roof' => Icons.roofing_rounded,
  'golf_view' => Icons.sports_golf_rounded,
  'beach_access' => Icons.beach_access_rounded,
  'corner_unit' => Icons.turn_right_rounded,
  'parking' => Icons.local_parking_rounded,
  _ => Icons.check_circle_outline_rounded,
};

/// Two-column grid of feature tiles.
class FeatureGrid extends StatelessWidget {
  final List<String> keys;
  const FeatureGrid(this.keys, {super.key});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - kPropPad * 2 - 9) / 2;
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        for (final k in keys)
          Container(
            width: w,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: JV2.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: JV2.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: JV2.fillFaint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(amenityIcon(k), size: 15, color: JV2.navy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'find.am_$k'.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JV2.ink,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bottom bar: Message (WhatsApp) and Call seller. A button hides when its number is missing.
class ContactBar extends StatelessWidget {
  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  const ContactBar({super.key, this.onMessage, this.onCall});

  @override
  Widget build(BuildContext context) {
    if (onMessage == null && onCall == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(
        kPropPad,
        12,
        kPropPad,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF0FAFBFD),
        border: Border(top: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          if (onMessage != null)
            Expanded(
              flex: 100,
              child: GestureDetector(
                onTap: onMessage,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: JV2.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: JV2.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: JV2.ink,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'prop.message'.tr(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: JV2.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (onMessage != null && onCall != null) const SizedBox(width: 10),
          if (onCall != null)
            Expanded(
              flex: onMessage != null ? 115 : 100,
              child: JV2PrimaryButton(
                height: 52,
                onPressed: onCall,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.call_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'prop.call_seller'.tr(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
