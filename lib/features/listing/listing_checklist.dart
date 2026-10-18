import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/storage/app_storage.dart';
import '../../core/widgets/jv2.dart';
import '../explore/presentation/widgets/explore_widgets.dart' show isArabic;
import 'listing_api.dart';
import 'listing_draft.dart';
import 'listing_flow.dart';
import 'listing_widgets.dart' show grouped;

/// One line of the checklist: a label and what we have for it (null = still needed).
class ChecklistRow {
  final String label;
  final String? value;
  final String key;
  const ChecklistRow(this.key, this.label, this.value);
}

/// What a draft holds, row by row, in the order the form asks for it. Shared by the chat answer and the Tell Jeeran card.
List<ChecklistRow> checklistRows(
  ListingDraft d, {
  required bool ar,
  required bool paymentSet,
  bool admin = false,
}) {
  final c = d.compound;
  String sale() => switch (d.status) {
    'for_rent' => 'listing.rent'.tr(),
    'for_rent_furnished' => 'listing.rent_furnished'.tr(),
    _ => 'listing.sale'.tr(),
  };
  return [
    ChecklistRow(
      'type',
      'listing.f_type'.tr(),
      d.type == null ? null : '${'listing.t_${d.type}'.tr()} · ${sale()}',
    ),
    ChecklistRow(
      'sale_type',
      'listing.f_sale_type'.tr(),
      'prop.sale_${d.effectiveListingType(admin: admin)}'.tr(),
    ),
    ChecklistRow(
      'compound',
      'listing.f_compound'.tr(),
      c == null
          ? null
          : [c.name(ar), c.sub(ar)].where((s) => s.isNotEmpty).join(' · '),
    ),
    if (!d.noRooms)
      ChecklistRow(
        'beds',
        'listing.f_beds'.tr(),
        d.bedroomsSet ? '${d.bedrooms}' : null,
      ),
    ChecklistRow(
      'size',
      'listing.f_size'.tr(),
      d.sizeValue == null ? null : '${d.size} m²',
    ),
    if (d.asksLand && d.landValue != null)
      ChecklistRow('land', 'listing.f_land'.tr(), '${d.land} m²'),
    if (d.asksGarden && d.groundGarden != null)
      ChecklistRow(
        'garden',
        'listing.f_ground_garden'.tr(),
        d.groundGarden!
            ? [
                'listing.yes'.tr(),
                if (d.gardenValue != null) '${d.garden} m²',
              ].join(' · ')
            : 'listing.no'.tr(),
      ),
    if (d.asksOutdoor && d.outdoor != null)
      ChecklistRow(
        'outdoor',
        'listing.f_outdoor'.tr(),
        d.outdoor!
            ? [
                'listing.yes'.tr(),
                if (d.outdoorValue != null) '${d.outdoorSize} m²',
              ].join(' · ')
            : 'listing.no'.tr(),
      ),
    if (d.level.trim().isNotEmpty)
      ChecklistRow('floor', 'listing.f_floor'.tr(), d.level),
    if (d.view != null)
      ChecklistRow('view', 'listing.f_view'.tr(), 'listing.v_${d.view}'.tr()),
    if (d.delivery != null)
      ChecklistRow(
        'delivery',
        'listing.f_delivery'.tr(),
        d.delivery == 'ready' ? 'listing.d_ready'.tr() : d.delivery,
      ),
    ChecklistRow(
      'price',
      (d.isRent
              ? 'listing.f_rent_price'
              : d.isResale
              ? 'listing.f_contract_total'
              : 'listing.f_price')
          .tr(),
      d.priceValue == null ? null : 'EGP ${grouped(d.priceValue!)}',
    ),
    if (!d.isRent)
      ChecklistRow(
        'payment',
        'listing.f_payment'.tr(),
        !paymentSet
            ? null
            : (d.payment == 'cash'
                  ? 'listing.cash'.tr()
                  : (d.isResale
                        ? 'listing.plan_text_amount'.tr(
                            args: [d.downAmount, d.years],
                          )
                        : 'listing.plan_text'.tr(args: [d.down, d.years]))),
      ),
    ChecklistRow(
      'photos',
      'listing.f_photos'.tr(),
      d.photoCount > 0 ? '${d.photoCount}' : null,
    ),
  ];
}

/// The listing checklist inside an AI answer (chat and voice): what the assistant understood, what is still needed,
/// and a button into the full "Tell Jeeran" screen to finish it. Nothing is published from here.
class ListingChecklistCard extends StatelessWidget {
  final DraftReply reply;
  final String?
  said; // the person's words, so the written title and description can use them
  const ListingChecklistCard({super.key, required this.reply, this.said});

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final draft = ListingDraft()
      ..apply(reply.draft, reply.compound, reply.filled);
    final rows = checklistRows(
      draft,
      ar: ar,
      paymentSet: !reply.missing.contains('payment'),
      admin: AppStorage.isAdmin,
    );
    final done = rows.where((r) => r.value != null).length;
    return Container(
      key: const Key('listing-card'),
      decoration: BoxDecoration(
        color: JV2.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JV2.line),
        boxShadow: JV2.shadowMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: JV2.navy,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'listing.card_title'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                    ),
                  ),
                ),
                Text(
                  '$done / ${rows.length}',
                  key: const Key('listing-progress'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: JV2.inkSub,
                  ),
                ),
              ],
            ),
          ),
          for (final r in rows)
            Container(
              key: Key('listing-row-${r.key}'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: r.value == null ? const Color(0xFFFAF7F1) : null,
                border: const Border(top: BorderSide(color: JV2.line)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      r.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: JV2.inkSub),
                    ),
                  ),
                  Expanded(
                    child: r.value == null
                        ? Text(
                            'listing.needed'.tr(),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8A5A12),
                            ),
                          )
                        : Text(
                            r.value!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: JV2.ink,
                            ),
                          ),
                  ),
                  if (r.value != null)
                    const Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: JV2.success,
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: JV2PrimaryButton(
              key: const Key('listing-continue'),
              height: 46,
              onPressed: () =>
                  ListingFlow.openFromChat(context, reply, said: said),
              child: Text('listing.continue_listing'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
