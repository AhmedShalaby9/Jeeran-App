import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/jv2.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../news/domain/entities/news.dart';
import '../../../news/v2/news_api.dart';
import '../../../news/v2/news_article_page.dart';
import '../../../news/v2/news_widgets.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../compounds/presentation/pages/compound_page.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/presentation/pages/property_details_page.dart';
import 'explore_widgets.dart';

String _localized(BuildContext context, String? ar, String? en) {
  final arabic = isArabic(context);
  final a = ar ?? '', e = en ?? '';
  return arabic ? (a.isNotEmpty ? a : e) : (e.isNotEmpty ? e : a);
}

// ── New launches strip ────────────────────────────────────

class LaunchStrip extends StatelessWidget {
  final List<Project> projects;

  const LaunchStrip({super.key, required this.projects});

  static const _tints = [
    Color(0x471A4A80),
    Color(0x4DB8893D),
    Color(0x3D12395F),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: projects.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = projects[i];
          final dev = p.developer?.name;
          final area = _localized(context, p.areaAr, p.areaEn).isNotEmpty
              ? _localized(context, p.areaAr, p.areaEn)
              : p.areaLabel;
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompoundPage(compoundId: p.id, name: p.name),
              ),
            ),
            child: SizedBox(
              width: 176,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Photo(
                    url: p.coverImage,
                    height: 118,
                    tint: _tints[i % _tints.length],
                    child: p.isNewLaunch
                        ? PositionedDirectional(
                            top: 9,
                            start: 9,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xEBFFFFFF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'explore.new_launch'.tr().toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: JV2.gold,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _localized(context, p.nameAr, p.nameEn),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (dev != null && dev.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      dev,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: JV2.inkSub),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (area != null && area.isNotEmpty) area,
                      if (p.minPrice != null)
                        'explore.from_price'.tr(args: [_compact(p.minPrice!)]),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: JV2.inkMute),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 11900000 → 11.9M, 750000 → 750K
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

// ── Property card with Project → Developer backlink ───────

class ExplorePropertyCard extends StatefulWidget {
  final Property property;

  const ExplorePropertyCard({super.key, required this.property});

  @override
  State<ExplorePropertyCard> createState() => _ExplorePropertyCardState();
}

class _ExplorePropertyCardState extends State<ExplorePropertyCard> {
  late bool _saved = widget.property.isFavorited;

  void _toggleSaved() {
    final bloc = context.read<FavoritesBloc>();
    setState(() => _saved = !_saved);
    bloc.add(
      _saved
          ? AddFavoriteEvent(widget.property.id)
          : RemoveFavoriteEvent(widget.property.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final project = p.project;
    final price = double.tryParse(p.price ?? '');
    final priceText = price == null
        ? '—'
        : NumberFormat.decimalPattern(context.locale.toString()).format(price);
    final title = _localized(context, p.titleAr, p.titleEn);
    final dev = project?.developer?.name;
    final area = project == null
        ? null
        : (_localized(context, project.areaAr, project.areaEn).isNotEmpty
              ? _localized(context, project.areaAr, project.areaEn)
              : project.areaLabel);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PropertyDetailsPage(property: p)),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: JV2.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JV2.line),
          boxShadow: JV2.shadowMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Photo(
              url: p.coverImage,
              height: 186,
              radius: 0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (p.isFeatured)
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [JV2.goldHi, JV2.gold],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66B8893D),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'explore.featured'.tr().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: GestureDetector(
                      onTap: _toggleSaved,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xEBFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: _saved ? JV2.danger : JV2.navy,
                        ),
                      ),
                    ),
                  ),
                  if (p.images.length > 1)
                    PositionedDirectional(
                      bottom: 10,
                      end: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xB80B2A4A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '1 / ${p.images.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        priceText,
                        style: JV2
                            .display(context, 25)
                            .copyWith(letterSpacing: -0.3),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'explore.egp'.tr(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: JV2.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (p.bedrooms != null)
                        _Meta(Icons.bed_outlined, '${p.bedrooms}'),
                      if (p.bathrooms != null)
                        _Meta(Icons.bathtub_outlined, '${p.bathrooms}'),
                      if (p.size != null && p.size!.isNotEmpty)
                        _Meta(
                          Icons.square_foot_rounded,
                          '${(double.tryParse(p.size!) ?? 0).round()} ${'explore.sqm'.tr()}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            if (project != null)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompoundPage(
                      compoundId: project.id,
                      name: project.name,
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: JV2.fillFaint,
                    border: Border(top: BorderSide(color: JV2.line)),
                  ),
                  child: Row(
                    children: [
                      Photo(
                        url: project.coverImage,
                        width: 30,
                        height: 30,
                        radius: 9,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localized(
                                context,
                                project.nameAr,
                                project.nameEn,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: JV2.ink,
                              ),
                            ),
                            Text(
                              [
                                if (dev != null && dev.isNotEmpty) dev,
                                if (area != null && area.isNotEmpty) area,
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: JV2.inkMute,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(chevronIcon(context), size: 16, color: JV2.inkMute),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: JV2.inkMute),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12, color: JV2.inkSub)),
        ],
      ),
    );
  }
}

// ── News rail ─────────────────────────────────────────────

/// The top stories, as the same rows the news list uses.
class NewsRail extends StatelessWidget {
  final List<News> news;

  const NewsRail({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (final n in news)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NewsRow(
                item: NewsItem(
                  id: n.id,
                  title: n.title,
                  body: n.content,
                  media: n.media,
                  publishedAt: DateTime.tryParse(n.publishedAt),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NewsArticlePage(id: n.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Top compounds ─────────────────────────────────────────

/// "Most viewed this month": ranked cards, #1 first.
class TopCompoundsRail extends StatelessWidget {
  final List<Project> projects;

  const TopCompoundsRail({super.key, required this.projects});

  static const _tints = [
    Color(0x471A4A80),
    Color(0x4DB8893D),
    Color(0x38137A55),
    Color(0x3D12395F),
    Color(0x38B8893D),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: projects.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = projects[i];
          final dev = p.developer?.name;
          final area = _localized(context, p.areaAr, p.areaEn).isNotEmpty
              ? _localized(context, p.areaAr, p.areaEn)
              : p.areaLabel;
          return GestureDetector(
            key: Key('top-compound-${p.id}'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompoundPage(compoundId: p.id, name: p.name),
              ),
            ),
            child: Container(
              width: 214,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: JV2.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: JV2.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Photo(
                    url: p.coverImage,
                    height: 124,
                    radius: 0,
                    tint: _tints[i % _tints.length],
                    child: PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 28),
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xF0FFFFFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: JV2
                              .display(context, 15)
                              .copyWith(color: JV2.navy),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _localized(context, p.nameAr, p.nameEn),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: JV2.ink,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (dev != null && dev.isNotEmpty) dev,
                            if (area != null && area.isNotEmpty) area,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: JV2.inkSub,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: JV2.line)),
                          ),
                          child: Row(
                            children: [
                              if (p.minPrice != null)
                                Flexible(
                                  child: Text(
                                    'explore.top_from'.tr(
                                      args: [_compact(p.minPrice!)],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: JV2.ink,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if ((p.unitsCount ?? 0) > 0)
                                Text(
                                  'explore.top_units'.tr(
                                    args: ['${p.unitsCount}'],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: JV2.inkSub,
                                  ),
                                ),
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
        },
      ),
    );
  }
}
