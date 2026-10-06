import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/jv2.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../../follow/presentation/follow_pill.dart';
import '../../data/models/saved_models.dart';

String _pickName(BuildContext context, String? ar, String? en) {
  final a = ar ?? '', e = en ?? '';
  return isArabic(context) ? (a.isNotEmpty ? a : e) : (e.isNotEmpty ? e : a);
}

String _money(BuildContext context, num n) =>
    NumberFormat.decimalPattern(context.locale.toString()).format(n);

String _compact(double n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    final v = n / 1000;
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}K';
  }
  return n.toInt().toString();
}

// ── Listings ──────────────────────────────────────────────

class SavedListingRow extends StatelessWidget {
  final SavedListing item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const SavedListingRow({super.key, required this.item, required this.onOpen, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = item.property;
    final price = double.tryParse(p.price ?? '');
    final title = _pickName(context, p.titleAr, p.titleEn);
    final project = p.project;
    final dev = project?.developer?.name;
    final sub = [
      if (project != null) _pickName(context, project.nameAr, project.nameEn),
      if (dev != null && dev.isNotEmpty) dev,
    ].join(' · ');

    return Opacity(
      opacity: item.isGone ? 0.72 : 1,
      child: GestureDetector(
        onTap: item.isGone && !item.isSold ? null : onOpen,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JV2.line),
            boxShadow: const [BoxShadow(color: Color(0x0D0B2A4A), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Row(
            children: [
              Photo(
                url: p.coverImage,
                width: 100,
                height: 100,
                radius: 12,
                child: item.isGone
                    ? Container(
                        color: const Color(0x8C0B2A4A),
                        alignment: Alignment.center,
                        child: Text(
                          (item.isSold ? 'saved.sold' : 'saved.unavailable').tr().toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            price == null ? '—' : _money(context, price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: JV2.display(context, 19).copyWith(letterSpacing: -0.2),
                          ),
                        ),
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: JV2.fillFaint,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: JV2.line),
                            ),
                            child: const Icon(Icons.favorite_rounded, size: 14, color: JV2.gold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: JV2.ink),
                    ),
                    const SizedBox(height: 5),
                    if (sub.isNotEmpty)
                      Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
                    const SizedBox(height: 7),
                    if (item.hasDropped)
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 12, color: JV2.success),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'saved.price_drop'.tr(args: ['−${_money(context, item.priceChange.abs())}']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: JV2.success),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          if (p.bedrooms != null) _Meta(Icons.bed_outlined, '${p.bedrooms}'),
                          if (p.bathrooms != null) _Meta(Icons.bathtub_outlined, '${p.bathrooms}'),
                          if (p.size != null && p.size!.isNotEmpty)
                            _Meta(Icons.square_foot_rounded,
                                '${(double.tryParse(p.size!) ?? 0).round()} ${'explore.sqm'.tr()}'),
                        ],
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

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: JV2.inkSub),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
      ],
    ),
  );
}

// ── Compounds ─────────────────────────────────────────────

/// The latest-update strip shared by compound cards and developer rows.
class _UpdateStrip extends StatelessWidget {
  final SavedUpdate update;
  final bool framed; // compound cards frame it; developer rows run it edge to edge
  final VoidCallback onTap;

  const _UpdateStrip({required this.update, required this.framed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fresh = update.isFresh;
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: fresh || !framed ? JV2.goldHi : JV2.inkSub, shape: BoxShape.circle),
    );
    final text = Expanded(
      child: Text(
        update.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: JV2.ink),
      ),
    );
    final chevron = Icon(chevronIcon(context), size: 14, color: JV2.inkSub);

    if (!framed) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: JV2.line))),
          child: Row(children: [dot, const SizedBox(width: 9), text, chevron]),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: fresh ? JV2.goldFilm : JV2.fillFaint,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: fresh ? JV2.goldEdge : JV2.line),
        ),
        child: Row(children: [dot, const SizedBox(width: 9), text, chevron]),
      ),
    );
  }
}

class SavedCompoundCard extends StatelessWidget {
  final SavedCompound item;
  final VoidCallback onOpen;
  final VoidCallback onUnfollow;
  final VoidCallback onOpenUpdate;

  const SavedCompoundCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onUnfollow,
    required this.onOpenUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.project;
    final area = _pickName(context, p.areaAr, p.areaEn).isNotEmpty
        ? _pickName(context, p.areaAr, p.areaEn)
        : p.areaLabel;
    final dev = p.developer?.name;
    final sub = [if (dev != null && dev.isNotEmpty) dev, if (area != null && area.isNotEmpty) area].join(' · ');
    final update = item.latestUpdate;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JV2.line),
          boxShadow: const [BoxShadow(color: Color(0x0D0B2A4A), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Photo(
              url: p.coverImage,
              height: 112,
              radius: 0,
              child: item.isFresh
                  ? PositionedDirectional(
                      top: 10,
                      start: 10,
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
                          'saved.new_release'.tr().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickName(context, p.nameAr, p.nameEn),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: JV2.ink, letterSpacing: -0.2),
                            ),
                            const SizedBox(height: 3),
                            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FollowPill(following: true, onTap: onUnfollow),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      _Stat(label: 'saved.units'.tr(), value: '${p.unitsCount ?? 0}'),
                      Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 12), color: JV2.line),
                      _Stat(
                        label: 'saved.from'.tr(),
                        value: p.minPrice == null ? '—' : '${_compact(p.minPrice!)} ${'explore.egp'.tr()}',
                      ),
                    ],
                  ),
                  if (update != null) ...[
                    const SizedBox(height: 12),
                    _UpdateStrip(update: update, framed: true, onTap: onOpenUpdate),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: JV2.inkSub),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: JV2.ink,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

// ── Developers ────────────────────────────────────────────

class SavedDeveloperRow extends StatelessWidget {
  final SavedDeveloper item;
  final VoidCallback onOpen;
  final VoidCallback onUnfollow;
  final VoidCallback onOpenUpdate;

  const SavedDeveloperRow({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onUnfollow,
    required this.onOpenUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.decimalPattern(context.locale.toString());
    final parts = [
      'saved.developer'.tr(),
      if (item.projectsCount > 0) 'saved.compounds_count'.tr(args: ['${item.projectsCount}']),
      'explore.listings_count'.tr(args: [f.format(item.listingsCount)]),
    ];
    final update = item.latestUpdate;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JV2.line),
        boxShadow: const [BoxShadow(color: Color(0x0D0B2A4A), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onOpen,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: JV2.line),
                      gradient: const LinearGradient(
                        begin: Alignment(-0.5, -1),
                        end: Alignment(0.5, 1),
                        colors: [Color(0xFFF6F8FB), Color(0xFFE4EAF1)],
                      ),
                    ),
                    child: (item.logo ?? '').isNotEmpty
                        ? Photo(url: item.logo, width: 42, height: 42, radius: 12)
                        : Text(item.short, style: JV2.display(context, 16).copyWith(color: JV2.navy, letterSpacing: 0.3)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: JV2.ink, height: 1.25),
                              ),
                            ),
                            if (item.isVerified) ...[
                              const SizedBox(width: 5),
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.verified_user_outlined, size: 13, color: JV2.success),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(parts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: JV2.inkSub)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FollowPill(following: true, compact: true, onTap: onUnfollow),
                ],
              ),
            ),
          ),
          if (update != null) _UpdateStrip(update: update, framed: false, onTap: onOpenUpdate),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────

class SavedEmptyState extends StatelessWidget {
  final String titleKey;
  final String subKey;
  final IconData icon;

  const SavedEmptyState({super.key, required this.titleKey, required this.subKey, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: JV2.fillFaint,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: JV2.line),
              ),
              child: Icon(icon, size: 26, color: JV2.navy),
            ),
            const SizedBox(height: 13),
            Text(titleKey.tr(), textAlign: TextAlign.center, style: JV2.display(context, 21)),
            const SizedBox(height: 13),
            Text(subKey.tr(), textAlign: TextAlign.center, style: JV2.sub.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
