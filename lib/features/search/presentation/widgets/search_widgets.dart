import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../data/search_api.dart';
import '../../data/search_filters.dart';

const double kSearchPad = 20;

// ── a listing, as the Search rows need it ─────────────────

/// Reads what a result row shows out of a raw `/properties` item.
class UnitView {
  final Map<String, dynamic> raw;
  UnitView(this.raw);

  bool _ar(BuildContext c) => isArabic(c);
  String _pick(BuildContext c, String key, [Map<String, dynamic>? from]) {
    final m = from ?? raw;
    final ar = (m['${key}_ar'] as String?) ?? '';
    final en = (m['${key}_en'] as String?) ?? '';
    return _ar(c) ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
  }

  Map<String, dynamic>? get _compound {
    final c = raw['compound'] ?? raw['project'];
    return c is Map<String, dynamic> ? c : null;
  }

  double? get price => double.tryParse('${raw['price'] ?? ''}');
  String title(BuildContext c) => _pick(c, 'title');
  String compoundName(BuildContext c) =>
      _compound == null ? '' : _pick(c, 'name', _compound);
  String developerName(BuildContext c) {
    final d = _compound?['developer'];
    return d is Map<String, dynamic> ? _pick(c, 'name', d) : '';
  }

  int? get beds => (raw['bedrooms'] as num?)?.toInt();
  int? get baths => (raw['bathrooms'] as num?)?.toInt();
  num? get size => double.tryParse('${raw['size'] ?? ''}');
  bool get featured => raw['is_featured'] == true;
  String? get image {
    final i = raw['images'];
    return i is List && i.isNotEmpty && i.first is String
        ? i.first as String
        : null;
  }

  /// 'Ready' or the delivery year, from the inherited `effective` block.
  String? get delivery {
    final e = raw['effective'];
    if (e is! Map) return null;
    if (e['is_ready'] == true) return 'find.delivery_tag_ready'.tr();
    final d = e['delivery_date'];
    final date = d is String ? DateTime.tryParse(d) : null;
    return date == null ? null : '${date.year}';
  }
}

String priceText(BuildContext context, double? price) => price == null
    ? '—'
    : NumberFormat.decimalPattern(context.locale.toString()).format(price);

// ── query bar ─────────────────────────────────────────────

class SearchQueryBar extends StatelessWidget {
  final String query;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const SearchQueryBar({
    super.key,
    required this.query,
    required this.onTap,
    this.showBack = false,
    this.onBack,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        kSearchPad,
        MediaQuery.of(context).padding.top + 8,
        kSearchPad,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xE6FAFBFD),
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _SquareButton(
              icon: isRtl(context)
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              onTap: onBack,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: JV2.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: query.isNotEmpty ? JV2.goldEdge : JV2.line,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: JV2.inkSub,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        query.isEmpty ? 'find.placeholder'.tr() : query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: query.isEmpty ? JV2.inkSub : JV2.ink,
                        ),
                      ),
                    ),
                    if (query.isNotEmpty && onClear != null)
                      GestureDetector(
                        onTap: onClear,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: JV2.inkSub,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SquareButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: JV2.line),
      ),
      child: Icon(icon, size: 22, color: JV2.ink),
    ),
  );
}

/// Header of the sub-screens (All developers, Launches & offers).
class SearchSubHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const SearchSubHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        kSearchPad,
        MediaQuery.of(context).padding.top + 8,
        kSearchPad,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xEBFAFBFD),
        border: Border(bottom: BorderSide(color: JV2.line)),
      ),
      child: Row(
        children: [
          _SquareButton(
            icon: isRtl(context)
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: JV2.ink,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(fontSize: 12, color: JV2.inkMute),
            ),
        ],
      ),
    );
  }
}

// ── Ask card ──────────────────────────────────────────────

class AskCard extends StatelessWidget {
  final VoidCallback onTap;
  const AskCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [JV2.navyLift, JV2.navy, Color(0xFF071D34)],
            stops: [0, 0.68, 1],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330B2A4A),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x24FFFFFF),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'find.ask_eyebrow'.tr().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.9,
                      color: Color(0xFFE5C48F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'find.ask_title'.tr(),
                    style: JV2
                        .display(context, 17)
                        .copyWith(color: Colors.white, height: 1.2),
                  ),
                ],
              ),
            ),
            Icon(
              chevronIcon(context),
              size: 18,
              color: const Color(0xB3FFFFFF),
            ),
          ],
        ),
      ),
    );
  }
}

// ── result row + skeleton ─────────────────────────────────

class UnitRow extends StatelessWidget {
  final UnitView unit;
  final VoidCallback onTap;
  const UnitRow({super.key, required this.unit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final meta = [
      u.compoundName(context),
      u.developerName(context),
    ].where((s) => s.isNotEmpty).join(' · ');
    final delivery = u.delivery;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Photo(
              url: u.image,
              width: 104,
              height: 104,
              radius: 12,
              child: u.featured
                  ? Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Container(
                        margin: const EdgeInsets.all(7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [JV2.goldHi, JV2.gold],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'explore.featured'.tr().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            priceText(context, u.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: JV2.display(context, 20),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'explore.egp'.tr(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: JV2.gold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      u.title(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: JV2.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: JV2.inkSub,
                        ),
                      ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 11,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (u.beds != null)
                          _Meta(Icons.bed_outlined, '${u.beds}'),
                        if (u.baths != null)
                          _Meta(Icons.bathtub_outlined, '${u.baths}'),
                        if (u.size != null)
                          _Meta(
                            Icons.square_foot_rounded,
                            '${u.size!.round()} ${'explore.sqm'.tr()}',
                          ),
                        if (delivery != null)
                          _DeliveryTag(
                            delivery,
                            ready:
                                u.raw['effective'] is Map &&
                                (u.raw['effective'] as Map)['is_ready'] == true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: JV2.inkSub),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: JV2.inkSub,
        ),
      ),
    ],
  );
}

class _DeliveryTag extends StatelessWidget {
  final String text;
  final bool ready;
  const _DeliveryTag(this.text, {required this.ready});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: ready ? const Color(0x1A137A55) : JV2.fillFaint,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: ready ? JV2.success : JV2.inkSub,
      ),
    ),
  );
}

class ResultsSkeleton extends StatefulWidget {
  const ResultsSkeleton({super.key});

  @override
  State<ResultsSkeleton> createState() => _ResultsSkeletonState();
}

class _ResultsSkeletonState extends State<ResultsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => FractionallySizedBox(
      widthFactor: w,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: JV2.fillHi,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(
        opacity: 0.55 + 0.45 * _c.value,
        child: Column(
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JV2.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: JV2.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: JV2.fillHi,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(.58, 17),
                          const SizedBox(height: 9),
                          bar(.8, 11),
                          const SizedBox(height: 9),
                          bar(.46, 11),
                          const SizedBox(height: 13),
                          bar(.66, 11),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── headings and chips ────────────────────────────────────

class SearchSectionHead extends StatelessWidget {
  final String eyebrow;
  final String title;
  final VoidCallback? onAction;
  const SearchSectionHead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(kSearchPad, 0, kSearchPad, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: JV2.eyebrow.copyWith(fontSize: 10, letterSpacing: 1.8),
              ),
              const SizedBox(height: 5),
              Text(title, style: JV2.display(context, 24)),
            ],
          ),
        ),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'find.see_all'.tr(),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: JV2.navy,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The navy "Filters" pill with a count badge.
class FiltersButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const FiltersButton({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: JV2.navy,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B2A4A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            'find.filters'.tr(),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 16),
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x38FFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// A removable chip (active filter).
class RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const RemovableChip({super.key, required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
    decoration: BoxDecoration(
      color: JV2.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: JV2.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: JV2.ink,
          ),
        ),
        const SizedBox(width: 7),
        GestureDetector(
          onTap: onRemove,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: JV2.fillHi,
            ),
            child: const Icon(Icons.close_rounded, size: 11, color: JV2.inkSub),
          ),
        ),
      ],
    ),
  );
}

/// Chip with a dropdown menu — the four quick narrowers in Browse.
class QuickChip<T> extends StatelessWidget {
  final String label;
  final String? value; // shown instead of the label when set
  final List<(T? key, String text)> options; // first option = "any"
  final T? selected;
  final ValueChanged<T?> onPick;
  const QuickChip({
    super.key,
    required this.label,
    required this.options,
    required this.onPick,
    this.value,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final on = value != null;
    return PopupMenuButton<int>(
      onSelected: (i) => onPick(options[i].$1),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: JV2.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: JV2.line),
      ),
      itemBuilder: (_) => [
        for (var i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            height: 40,
            child: Text(
              options[i].$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: (selected == options[i].$1)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: (selected == options[i].$1) ? JV2.gold : JV2.ink,
              ),
            ),
          ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: on ? JV2.goldFilm : JV2.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? JV2.goldEdge : JV2.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                color: on ? JV2.gold : JV2.inkSub,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: on ? JV2.gold : JV2.inkMute,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Newest ⌄" sort menu.
class SortMenu extends StatelessWidget {
  final String sort;
  final ValueChanged<String> onPick;
  const SortMenu({super.key, required this.sort, required this.onPick});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    onSelected: onPick,
    color: JV2.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: JV2.line),
    ),
    itemBuilder: (_) => [
      for (final s in SearchFilters.sorts)
        PopupMenuItem(
          value: s,
          height: 40,
          child: Text(
            'find.sort_$s'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: s == sort ? FontWeight.w700 : FontWeight.w500,
              color: s == sort ? JV2.gold : JV2.ink,
            ),
          ),
        ),
    ],
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'find.sort_$sort'.tr(),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: JV2.navy,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: JV2.navy,
        ),
      ],
    ),
  );
}

// ── developers + launches ─────────────────────────────────

class DevAvatar extends StatelessWidget {
  final DeveloperSummary d;
  final double size;
  final double radius;
  const DevAvatar(this.d, {super.key, this.size = 72, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: JV2.line),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4F7FB), Color(0xFFE1E8F0)],
              ),
            ),
            child: (d.logo ?? '').isNotEmpty
                ? Photo(url: d.logo, width: size, height: size, radius: radius)
                : Text(
                    d.short,
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w700,
                      color: JV2.navy,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
          if (d.isVerified)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: JV2.line),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 11,
                  color: JV2.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DevRailCard extends StatelessWidget {
  final DeveloperSummary d;
  final VoidCallback onTap;
  const DevRailCard({super.key, required this.d, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(13, 14, 13, 13),
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JV2.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DevAvatar(d),
            const SizedBox(height: 10),
            Text(
              d.name(ar),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JV2.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'find.n_compounds'.plural(d.compounds),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: JV2.inkMute),
            ),
            const SizedBox(height: 2),
            Text(
              'find.n_units'.plural(d.units),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JV2.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DevListRow extends StatelessWidget {
  final DeveloperSummary d;
  final VoidCallback onTap;
  const DevListRow({super.key, required this.d, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JV2.line),
        ),
        child: Row(
          children: [
            DevAvatar(d, size: 46, radius: 14),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name(ar),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${'find.n_compounds'.plural(d.compounds)} · ${'find.n_units'.plural(d.units)}',
                    style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                  ),
                ],
              ),
            ),
            Icon(chevronIcon(context), size: 16, color: JV2.inkMute),
          ],
        ),
      ),
    );
  }
}

String _duration(int? s) =>
    s == null ? '' : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// A launch or offer. `wide` is the full-width version on the Launches & offers screen.
class LaunchCard extends StatelessWidget {
  final PromotionItem p;
  final bool wide;
  final VoidCallback onTap;
  const LaunchCard({
    super.key,
    required this.p,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final offer = p.type == 'offer';
    final sub = [
      if (p.sub(ar).isNotEmpty)
        p.sub(ar)
      else if (p.minPrice != null)
        'explore.from_price'.tr(args: [compactPrice(p.minPrice!)]),
      if (offer && p.endsAt != null)
        'find.ends'.tr(
          args: [DateFormat.MMMd(context.locale.toString()).format(p.endsAt!)],
        ),
    ].join(' · ');
    final caption = p.title(ar).isNotEmpty ? p.title(ar) : p.compoundName(ar);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? double.infinity : 195,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(wide ? 18 : 16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x290B2A4A),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Photo(
          url: p.image,
          height: wide ? 188 : 190,
          radius: 0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x420B2A4A),
                      Color(0x000B2A4A),
                      Color(0xBD0B2A4A),
                    ],
                    stops: [0, 0.32, 1],
                  ),
                ),
              ),
              if (p.hasVideo)
                Center(
                  child: Container(
                    width: wide ? 44 : 38,
                    height: wide ? 44 : 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xB3FFFFFF),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: JV2.navy,
                    ),
                  ),
                ),
              if (p.hasVideo && p.videoSeconds != null)
                PositionedDirectional(
                  top: 9,
                  end: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x9E0B2A4A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _duration(p.videoSeconds),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                top: 9,
                start: 9,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: offer
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [JV2.goldHi, JV2.gold],
                          )
                        : null,
                    color: offer ? null : const Color(0xF0FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (offer ? 'find.badge_offer' : 'find.badge_launch')
                        .tr()
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                      color: offer ? Colors.white : JV2.navy,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      caption,
                      maxLines: wide ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: wide
                          ? JV2
                                .display(context, 19)
                                .copyWith(color: Colors.white)
                          : const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xD6FFFFFF),
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      'find.ad_by'
                          .tr(args: [p.developerName(ar)])
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
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

// ── chip labels for the active filters ────────────────────

String _m(double v) => compactPrice(v);

/// (label, filters-without-it) for every active condition, in reading order.
List<(String, SearchFilters)> activeChips(
  BuildContext context,
  SearchFilters f,
) {
  final out = <(String, SearchFilters)>[];
  void add(String label, SearchFilters next) => out.add((label, next));

  if (f.areaId != null)
    add(f.areaName ?? 'find.s_area'.tr(), f.without('area'));
  if (f.compoundId != null)
    add(f.compoundName ?? 'find.s_compound'.tr(), f.without('compound'));
  if (f.developerId != null)
    add(f.developerName ?? 'find.s_developer'.tr(), f.without('developer'));
  for (final t in SearchOptions.types.where(f.types.contains)) {
    add('type.$t'.tr(), f.copyWith(types: {...f.types}..remove(t)));
  }
  if (f.status != null) add('find.st_${f.status}'.tr(), f.without('status'));
  if (f.minPrice != null && f.maxPrice != null) {
    add(
      'find.c_price_range'.tr(
        args: [_m(f.minPrice!.toDouble()), _m(f.maxPrice!.toDouble())],
      ),
      f.copyWith(minPrice: null, maxPrice: null),
    );
  } else if (f.minPrice != null) {
    add(
      'find.c_price_from'.tr(args: [_m(f.minPrice!.toDouble())]),
      f.without('price_min'),
    );
  } else if (f.maxPrice != null) {
    add(
      'find.c_price_to'.tr(args: [_m(f.maxPrice!.toDouble())]),
      f.without('price_max'),
    );
  }
  if (f.beds != null) {
    add(
      f.beds == '5+'
          ? 'find.beds_plus'.tr()
          : 'find.c_beds'.plural(int.parse(f.beds!)),
      f.without('bedrooms'),
    );
  }
  if (f.baths != null) {
    final n = int.tryParse(f.baths!.replaceAll('+', '')) ?? 0;
    add(
      f.baths!.endsWith('+')
          ? '$n+ ${'find.s_baths'.tr()}'
          : 'find.c_baths'.plural(n),
      f.without('bathrooms'),
    );
  }
  if (f.minSize != null && f.maxSize != null) {
    add(
      'find.c_size'.tr(args: ['${f.minSize}', '${f.maxSize}']),
      f.copyWith(minSize: null, maxSize: null),
    );
  } else if (f.minSize != null) {
    add('find.c_size_from'.tr(args: ['${f.minSize}']), f.without('size_min'));
  } else if (f.maxSize != null) {
    add('find.c_size_to'.tr(args: ['${f.maxSize}']), f.without('size_max'));
  }
  if (f.delivery != null) {
    add(
      f.delivery == 'ready'
          ? 'find.ready'.tr()
          : 'find.c_delivery_year'.tr(args: [f.delivery!]),
      f.without('delivery'),
    );
  }
  if (f.finishing != null)
    add('compound.fin_${f.finishing}'.tr(), f.without('finishing'));
  if (f.payment != null) add(paymentLabel(f.payment!), f.without('payment'));
  for (final a in SearchOptions.amenities.where(f.amenities.contains)) {
    add('find.am_$a'.tr(), f.copyWith(amenities: {...f.amenities}..remove(a)));
  }
  if (f.featured) add('find.c_featured'.tr(), f.without('featured'));
  if (f.verifiedOnly) add('find.c_verified'.tr(), f.without('verified'));
  return out;
}

String paymentLabel(String key) =>
    key == 'mortgage' ? 'find.pay_mortgage'.tr() : 'compound.pay_$key'.tr();

/// Short text for the query bar when the search has no typed text: "Chalet · North Coast".
String filterSummary(BuildContext context, SearchFilters f) {
  if (f.q.trim().isNotEmpty) return f.q.trim();
  return activeChips(context, f).take(2).map((c) => c.$1).join(' · ');
}
