import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/jv2.dart';
import '../../../explore/presentation/widgets/explore_widgets.dart';
import '../../../follow/presentation/follow_alerts.dart';
import '../../../properties/data/models/property_model.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../units/data/unit_format.dart';
import 'page_widgets.dart' show EmptyBlock;
import '../../../units/presentation/unit_card.dart';
import '../../../units/presentation/unit_widgets.dart';
import '../../data/compound_page_data.dart';

/// The Primary tab (design D3): the compound's units grouped by type, with a bedrooms filter.
class CompoundUnits extends StatefulWidget {
  final int compoundId;
  const CompoundUnits({super.key, required this.compoundId});

  @override
  State<CompoundUnits> createState() => _CompoundUnitsState();
}

class _CompoundUnitsState extends State<CompoundUnits> {
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
        queryParams: {
          'limit': 100,
          'compound_id': widget.compoundId,
          'listing_type': 'primary',
        },
      );
      final raw = res.data['data'];
      final items = (raw is List ? raw : const [])
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
    if (items.isEmpty)
      return EmptyBlock(
        icon: Icons.home_work_outlined,
        title: 'compound.primary_empty'.tr(),
      );
    // groups in the order the types first appear
    final groups = <String, List<Property>>{};
    for (final p in items) {
      groups.putIfAbsent(p.propertyType ?? 'apartment', () => []).add(p);
    }
    final allByType = <String, int>{};
    for (final p in items) {
      allByType[p.propertyType ?? 'apartment'] =
          (allByType[p.propertyType ?? 'apartment'] ?? 0) + 1;
    }
    final date = items
        .map((p) => p.sourceDate)
        .whereType<String>()
        .fold<String?>(null, (a, b) => a == null || b.compareTo(a) > 0 ? b : a);
    final published = date == null ? null : DateTime.tryParse(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in groups.entries) ...[
          Row(
            children: [
              Icon(typeIcon(e.key), size: 15, color: JV2.navy),
              const SizedBox(width: 7),
              Text(
                'type.${e.key}'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: JV2.ink,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'unit.models_n'.tr(
                  namedArgs: {'n': '${allByType[e.key] ?? e.value.length}'},
                ),
                style: const TextStyle(fontSize: 12, color: JV2.inkMute),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final p in e.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: UnitCard(property: p, compact: true),
            ),
        ],
        Center(
          child: Text(
            published == null
                ? 'unit.published_prices_nodate'.tr()
                : 'unit.published_prices'.tr(
                    namedArgs: {
                      'date': DateFormat(
                        'd MMM y',
                        context.locale.toString(),
                      ).format(published),
                    },
                  ),
            style: const TextStyle(fontSize: 11.5, color: JV2.inkMute),
          ),
        ),
      ],
    );
  }
}

/// "No units listed yet" with a Follow button (design D3c): the compound stays visible, and following tells the buyer when units appear.
class NoUnitsBlock extends StatelessWidget {
  final String name;
  final bool resale;
  final FollowController? follow;
  const NoUnitsBlock({
    super.key,
    required this.name,
    this.resale = false,
    this.follow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 6),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: JV2.fillHi,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: JV2.line),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 22,
              color: JV2.inkSub,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            resale ? 'unit.no_resale_title'.tr() : 'unit.no_units_title'.tr(),
            key: const Key('no-units-title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: JV2.ink,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              resale
                  ? 'unit.no_resale_text'.tr()
                  : 'unit.no_units_text'.tr(namedArgs: {'name': name}),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: JV2.inkSub,
              ),
            ),
          ),
          if (follow != null) ...[
            const SizedBox(height: 14),
            SizedBox(width: 190, child: FollowCta(c: follow!, height: 48)),
            const SizedBox(height: 12),
            Text(
              'unit.follow_note'.tr(),
              style: const TextStyle(fontSize: 11.5, color: JV2.inkMute),
            ),
          ],
        ],
      ),
    );
  }
}

/// The compound's questions and answers (About tab): one open at a time.
class FaqList extends StatefulWidget {
  final List<CompoundFaq> faqs;
  final bool arabic;
  const FaqList({super.key, required this.faqs, required this.arabic});

  @override
  State<FaqList> createState() => _FaqListState();
}

class _FaqListState extends State<FaqList> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    final faqs = widget.faqs;
    if (faqs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnitSecHead('unit.questions'.tr(), meta: '${faqs.length}'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: JV2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JV2.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < faqs.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(top: BorderSide(color: JV2.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        key: Key('faq-$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setState(() => _open = _open == i ? -1 : i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faqs[i].question.pick(widget.arabic),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: JV2.ink,
                                  ),
                                ),
                              ),
                              Icon(
                                _open == i
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: JV2.inkSub,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_open == i)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: Text(
                            faqs[i].answer.pick(widget.arabic),
                            key: Key('faq-answer-$i'),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              color: JV2.inkSub,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A description that shows four lines and opens with "Read more".
class ReadMoreText extends StatefulWidget {
  final String text;
  const ReadMoreText(this.text, {super.key});

  @override
  State<ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  bool _more = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final style = JV2.sub.copyWith(
          fontSize: 14,
          height: 1.6,
          color: JV2.ink,
        );
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 4,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: c.maxWidth);
        final overflow = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              key: const Key('about-text'),
              maxLines: _more ? null : 4,
              overflow: _more ? TextOverflow.visible : TextOverflow.ellipsis,
              style: style,
            ),
            if (overflow)
              GestureDetector(
                key: const Key('read-more'),
                onTap: () => setState(() => _more = !_more),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _more ? 'unit.show_less'.tr() : 'unit.read_more'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: JV2.navy,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "Top developer": the source's mark, kept apart from Jeeran's own verified tick.
class TopBadge extends StatelessWidget {
  final bool small;
  const TopBadge({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('top-badge'),
      height: small ? 20 : 24,
      padding: EdgeInsets.symmetric(horizontal: small ? 7 : 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E6),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: JV2.goldEdge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: small ? 10 : 12, color: JV2.goldHi),
          const SizedBox(width: 4),
          Text(
            'unit.top_developer'.tr(),
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: JV2.warnText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo tile; developers without a logo get their initials.
class LogoTile extends StatelessWidget {
  final String name;
  final String? logo;
  final double size;
  const LogoTile({super.key, required this.name, this.logo, this.size = 64});

  String get _initials => name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z؀-ۿ]').hasMatch(w[0]))
      .take(2)
      .map((w) => w[0])
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final has = (logo ?? '').isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: has ? Colors.white : null,
        gradient: has
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4F7FA), Color(0xFFE7ECF2)],
              ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: JV2.line),
        boxShadow: JV2.shadowMd,
      ),
      child: has
          ? Photo(url: logo, width: size, height: size, radius: size * 0.28)
          : Text(
              _initials,
              style: JV2
                  .display(context, size * 0.38)
                  .copyWith(color: JV2.navy, letterSpacing: 0.5),
            ),
    );
  }
}

/// The developer card on the About tab.
class DevMiniCard extends StatelessWidget {
  final CompoundDeveloperBrief dev;
  final bool arabic;
  final VoidCallback onTap;
  const DevMiniCard({
    super.key,
    required this.dev,
    required this.arabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = dev.name.pick(arabic);
    return GestureDetector(
      key: const Key('dev-card'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JV2.line),
          boxShadow: JV2.shadowMd,
        ),
        child: Row(
          children: [
            LogoTile(name: name, logo: dev.logo, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: JV2.ink,
                          ),
                        ),
                      ),
                      if (dev.isTop) ...[
                        const SizedBox(width: 7),
                        const TopBadge(small: true),
                      ],
                    ],
                  ),
                  if (dev.compoundsCount > 0 || dev.unitsCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'unit.dev_counts'.tr(
                          namedArgs: {
                            'c': '${dev.compoundsCount}',
                            'u': '${dev.unitsCount}',
                          },
                        ),
                        style: const TextStyle(fontSize: 12, color: JV2.inkSub),
                      ),
                    ),
                ],
              ),
            ),
            Icon(chevronIcon(context), size: 18, color: JV2.inkMute),
          ],
        ),
      ),
    );
  }
}

/// "From EGP 2.4M | 56–168 m²" under the compound's name.
class CompoundPriceLine extends StatelessWidget {
  final double minPrice;
  final double? sizeMin;
  final double? sizeMax;
  const CompoundPriceLine({
    super.key,
    required this.minPrice,
    this.sizeMin,
    this.sizeMax,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 4,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${'unit.from'.tr()} '),
              TextSpan(
                text: '${'unit.egp'.tr()} ${fmtShort(minPrice)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          key: const Key('compound-from'),
          style: const TextStyle(fontSize: 15, color: JV2.ink),
        ),
        if (sizeMin != null && sizeMax != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 14, color: JV2.line),
              const SizedBox(width: 14),
              Text(
                '${rangeNum(sizeMin!, sizeMax!)} ${'unit.m2'.tr()}',
                style: const TextStyle(fontSize: 14, color: JV2.inkSub),
              ),
            ],
          ),
      ],
    );
  }
}

/// Chips for the unit types the compound has.
class TypeChips extends StatelessWidget {
  final List<String> types;
  const TypeChips(this.types, {super.key});

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in types)
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: JV2.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: JV2.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon(t), size: 15, color: JV2.navy),
                const SizedBox(width: 6),
                Text(
                  'type.$t'.tr(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: JV2.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
