import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/navigation/shared_element_route.dart';
import '../../../core/widgets/jv2.dart';
import '../../../core/widgets/shared_photo.dart';
import '../../explore/presentation/widgets/explore_widgets.dart';
import '../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../properties/domain/entities/property.dart';
import '../../properties/presentation/pages/property_details_page.dart';
import '../data/unit_format.dart';
import 'unit_widgets.dart';

/// The unit card of the Nawy data update (design D1): short price, "From … / quarter", Launch / Offer marks,
/// the building under the title, facts that never say "0 beds", and the compound's photo when the unit has none.
class UnitCard extends StatefulWidget {
  final Property property;
  final bool compact;
  const UnitCard({super.key, required this.property, this.compact = false});

  @override
  State<UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<UnitCard> {
  // one tag per card on screen (the same unit can be on a screen twice); the property page flies the same photo in
  late final String _heroTag = 'unit-photo-${widget.property.id}-${identityHashCode(this)}';
  late bool _saved = widget.property.isFavorited || (sl.isRegistered<FavoritesBloc>() && sl<FavoritesBloc>().isFavorited(widget.property.id));

  void _toggleSaved() {
    // the app-wide instance (as the property page uses): this card also opens in routes that do not provide the bloc
    final bloc = sl<FavoritesBloc>();
    setState(() => _saved = !_saved);
    bloc.add(_saved ? AddFavoriteEvent(widget.property.id) : RemoveFavoriteEvent(widget.property.id));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final ar = isArabic(context);
    final lang = ar ? 'ar' : 'en';
    final project = p.project;
    final price = double.tryParse(p.price ?? '');
    final size = double.tryParse(p.size ?? '');
    final compoundName = project == null ? '' : (ar ? (project.nameAr.isNotEmpty ? project.nameAr : project.nameEn) : (project.nameEn.isNotEmpty ? project.nameEn : project.nameAr));
    final building = p.localBuilding(lang);
    final sub = [if (building != null) building, if (compoundName.isNotEmpty) compoundName].join(' · ');
    final hasOwnPhoto = p.coverImage != null;
    final cover = p.coverImage ?? project?.coverImage;
    final plan = fromPerPeriod(p.cardPlan);
    final beds = (p.bedrooms ?? 0) > 0 ? 'unit.bd'.tr(namedArgs: {'n': '${p.bedrooms}'}) : null;
    final baths = (p.bathrooms ?? 0) > 0 ? 'unit.ba'.tr(namedArgs: {'n': '${p.bathrooms}'}) : null;
    final sMin = p.sizeMin ?? size, sMax = p.sizeMax ?? size;
    final sizeText = sMin == null || sMax == null ? null : '${rangeNum(sMin, sMax)} ${'unit.m2'.tr()}';
    final typeLabel = (p.propertyType == null) ? null : 'type.${p.propertyType}'.tr();
    final finishing = p.finishing == null ? null : 'listing.fin_${p.finishing}'.tr();
    final year = p.deliveryYear;

    return GestureDetector(
      key: Key('unit-card-${p.id}'),
      onTap: () => Navigator.push(context, sharedElementRoute(PropertyDetailsPage(property: p, heroTag: _heroTag))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: JV2.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: JV2.line), boxShadow: JV2.shadowMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: widget.compact ? 120 : 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SharedPhoto(tag: _heroTag, child: Photo(url: cover, radius: 0)),
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (p.isFeatured) ...[_FeaturedPill(), const SizedBox(width: 6)],
                      if (p.isLaunch) ...[const UnitTag.launch(), const SizedBox(width: 6)],
                      if (p.hasOffer) UnitTag.offer(pct: p.offerDiscountPercent),
                    ]),
                  ),
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: GestureDetector(
                      key: Key('unit-save-${p.id}'),
                      onTap: _toggleSaved,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: const Color(0xF0FFFFFF), borderRadius: BorderRadius.circular(17)),
                        child: Icon(_saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 17, color: _saved ? JV2.danger : JV2.ink),
                      ),
                    ),
                  ),
                  if (!hasOwnPhoto && cover != null)
                    PositionedDirectional(
                      end: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xEBFFFFFF), borderRadius: BorderRadius.circular(999)),
                        child: Text('unit.compound_photo'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: JV2.inkSub)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price == null ? '—' : '${'unit.egp'.tr()} ${fmtShort(price)}',
                        key: Key('unit-price-${p.id}'),
                        maxLines: 1,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: JV2.ink, letterSpacing: -0.2),
                      ),
                      if (plan != null) ...[
                        const SizedBox(width: 8),
                        Expanded(child: Text(plan, key: Key('unit-plan-${p.id}'), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(fontSize: 11.5, color: JV2.inkSub))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(p.localTitle(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35, color: JV2.ink)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: JV2.inkSub)),
                  ],
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.only(top: 9),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: JV2.line))),
                    width: double.infinity,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // studios, offices and shops have 0 bedrooms: say what they are instead
                        if (beds == null && typeLabel != null)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(typeIcon(p.propertyType), size: 14, color: JV2.navy),
                            const SizedBox(width: 5),
                            Text(typeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: JV2.ink)),
                          ]),
                        if (beds != null) Text(beds, style: const TextStyle(fontSize: 12, color: JV2.ink)),
                        if (baths != null) Text(baths, style: const TextStyle(fontSize: 12, color: JV2.ink)),
                        if (sizeText != null) Text(sizeText, style: const TextStyle(fontSize: 12, color: JV2.ink)),
                        if (finishing != null) Text(finishing, style: const TextStyle(fontSize: 12, color: JV2.inkSub)),
                        if (year != null) Text('unit.delivery_year'.tr(namedArgs: {'y': '$year'}), style: const TextStyle(fontSize: 12, color: JV2.inkSub)),
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

class _FeaturedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [JV2.goldHi, JV2.gold])),
        child: Text('explore.featured'.tr().toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: Colors.white)),
      );
}
