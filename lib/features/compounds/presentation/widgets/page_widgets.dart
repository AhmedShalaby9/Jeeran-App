import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/contact_call.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../explore/presentation/widgets/explore_cards.dart';
import '../../../properties/data/models/property_model.dart';
import '../../../properties/domain/entities/property.dart';

/// Pieces shared by the developer and compound pages.

/// The chip on a compound: New release / Offer / Selling / Resale only.
/// Returns null for a compound with nothing to say.
class CompoundStatusChip extends StatelessWidget {
  final String? status;
  const CompoundStatusChip(this.status, {super.key});

  static String? label(String? status) => switch (status) {
    'new_launch' => 'compound.new_release'.tr(),
    'offer' => 'compound.offer'.tr(),
    'selling' => 'compound.selling'.tr(),
    'resale_only' => 'compound.resale_only'.tr(),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final text = label(status);
    if (text == null) return const SizedBox.shrink();
    final (bg, fg) = switch (status) {
      'new_launch' => (JV2.navy, Colors.white),
      'offer' => (JV2.goldFilm, JV2.gold),
      'selling' => (const Color(0x1A137A55), JV2.success),
      _ => (JV2.fillHi, JV2.inkSub),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Three (or two) figures side by side under the title.
class StatStrip extends StatelessWidget {
  final List<(String value, String label)> stats;
  const StatStrip(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JV2.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                const VerticalDivider(width: 1, thickness: 1, color: JV2.line),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(stats[i].$1, style: JV2.display(context, 24)),
                    const SizedBox(height: 3),
                    Text(
                      stats[i].$2.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: JV2.inkMute,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Underlined segmented tabs.
class PageTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const PageTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == index ? JV2.navy : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: i == index
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: i == index ? JV2.navy : JV2.inkMute,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Label ……… value" row used by the About tabs.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: JV2.inkSub)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: JV2.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  const EmptyBlock({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: JV2.fillFaint,
            ),
            child: Icon(icon, color: JV2.inkMute, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: JV2.display(context, 21),
          ),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Text(
              sub!,
              textAlign: TextAlign.center,
              style: JV2.sub.copyWith(fontSize: 13.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom bar with a single phone button. Renders nothing when no contact phone is saved.
class CallBar extends StatelessWidget {
  final String label;
  final String?
  caption; // small line on the start side, e.g. the starting price
  final String? captionValue;
  const CallBar({
    super.key,
    required this.label,
    this.caption,
    this.captionValue,
  });

  @override
  Widget build(BuildContext context) {
    if (ContactCall.number == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: JV2.surface,
        border: Border(top: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          if (caption != null && captionValue != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  caption!,
                  style: const TextStyle(fontSize: 11, color: JV2.inkMute),
                ),
                const SizedBox(height: 2),
                Text(captionValue!, style: JV2.display(context, 22)),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: JV2PrimaryButton(
              height: 50,
              onPressed: () => ContactCall.dial(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A list of live listings loaded from `/properties` (legacy vocabulary — the
/// property model still reads `project`). Shows loading, empty and retry states.
class LiveListings extends StatefulWidget {
  final Map<String, dynamic> query;
  final String emptyText;
  const LiveListings({super.key, required this.query, required this.emptyText});

  @override
  State<LiveListings> createState() => _LiveListingsState();
}

class _LiveListingsState extends State<LiveListings> {
  List<Property>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final res = await sl<ApiClient>().get(
        ApiEndpoints.properties,
        queryParams: {'limit': 50, ...widget.query},
      );
      final raw = res.data['data'];
      final list = raw is List ? raw : const [];
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(PropertyModel.fromJson)
          .toList();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Text('explore.load_failed'.tr(), style: JV2.display(context, 20)),
            const SizedBox(height: 14),
            JV2PrimaryButton(
              width: 150,
              height: 44,
              onPressed: _load,
              child: Text('explore.try_again'.tr()),
            ),
          ],
        ),
      );
    }
    final items = _items;
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: JV2.navy)),
      );
    }
    if (items.isEmpty) {
      return EmptyBlock(
        icon: Icons.home_work_outlined,
        title: widget.emptyText,
      );
    }
    return Column(
      children: [
        for (final p in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ExplorePropertyCard(property: p),
          ),
      ],
    );
  }
}

/// Round white back button that stays legible on top of a photo.
class PhotoBackButton extends StatelessWidget {
  const PhotoBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: JV2.shadowMd,
        ),
        child: Icon(
          Directionality.of(context) == ui.TextDirection.rtl
              ? Icons.chevron_right_rounded
              : Icons.chevron_left_rounded,
          size: 24,
          color: JV2.ink,
        ),
      ),
    );
  }
}
