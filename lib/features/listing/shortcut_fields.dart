import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/jv2.dart';
import 'listing_api.dart';
import 'listing_draft.dart';
import 'listing_widgets.dart';

/// The fields on the assistant's card that can be filled by hand, right in the chat.
enum CardField {
  type,
  compound,
  beds,
  size,
  floor,
  view,
  delivery,
  price,
  payment,
}

/// Opens the right control for [field] in a bottom sheet and writes the answer straight into [draft].
/// [onChanged] runs after every change so the card behind the sheet updates live; [onPayment] tells the
/// card that the person chose how they are selling (cash or instalments), which the assistant has no
/// default for.
Future<void> editCardField(
  BuildContext context, {
  required CardField field,
  required ListingDraft draft,
  required ListingApi api,
  required bool ar,
  required VoidCallback onChanged,
  required VoidCallback onPayment,
}) async {
  if (field == CardField.compound) {
    final picked = await showModalBottomSheet<CompoundRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: JV2.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => CompoundPicker(api: api, ar: ar),
    );
    if (picked != null) {
      draft.compound = picked;
      draft.ai.remove('compound');
      onChanged();
    }
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: JV2.bgDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _FieldSheet(
      field: field,
      draft: draft,
      onChanged: onChanged,
      onPayment: onPayment,
    ),
  );
}

class _FieldSheet extends StatefulWidget {
  final CardField field;
  final ListingDraft draft;
  final VoidCallback onChanged, onPayment;
  const _FieldSheet({
    required this.field,
    required this.draft,
    required this.onChanged,
    required this.onPayment,
  });

  @override
  State<_FieldSheet> createState() => _FieldSheetState();
}

class _FieldSheetState extends State<_FieldSheet> {
  ListingDraft get _d => widget.draft;

  /// Writes through to the draft, repaints this sheet and the card behind it.
  void _set(String key, VoidCallback change) {
    change();
    _d.ai.remove(key);
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(kListPad, 12, kListPad, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: JV2.track,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ..._body(),
              const SizedBox(height: 20),
              JV2PrimaryButton(
                key: const Key('field-done'),
                height: 48,
                onPressed: () => Navigator.pop(context),
                child: Text('listing.done_field'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    switch (widget.field) {
      case CardField.type:
        return [
          ChipPicker(
            label: 'listing.f_type'.tr(),
            cols: 3,
            value: _d.type,
            options: [
              for (final t in ListingDraft.types) (t, 'listing.t_$t'.tr()),
            ],
            onChanged: (v) => _set('type', () => _d.type = v),
          ),
          const SizedBox(height: 16),
          ChipPicker(
            label: 'listing.f_purpose'.tr(),
            cols: 2,
            value: _d.status,
            options: [
              ('for_sale', 'listing.sale'.tr()),
              ('for_rent', 'listing.rent'.tr()),
            ],
            onChanged: (v) => _set('status', () => _d.status = v ?? 'for_sale'),
          ),
        ];
      case CardField.beds:
        return [
          ChipPicker(
            label: 'listing.f_beds'.tr(),
            cols: 4,
            value: _d.bedroomsSet ? '${_d.bedrooms}' : null,
            options: [
              for (var n = 1; n <= 7; n++) ('$n', n == 7 ? '7+' : '$n'),
            ],
            onChanged: (v) {
              if (v == null) return;
              _set('bedrooms', () {
                _d.bedrooms = int.parse(v);
                _d.bedroomsSet = true;
              });
            },
          ),
        ];
      case CardField.size:
        return [
          ListingInput(
            fieldKey: const Key('field-size'),
            label: 'listing.f_size'.tr(),
            value: _d.size,
            suffix: 'm²',
            numeric: true,
            onChanged: (v) => _set('size', () => _d.size = v),
          ),
        ];
      case CardField.floor:
        return [
          ListingInput(
            fieldKey: const Key('field-floor'),
            label: 'listing.f_floor'.tr(),
            value: _d.level,
            optional: true,
            onChanged: (v) => _set('level', () => _d.level = v),
          ),
        ];
      case CardField.view:
        return [
          ChipPicker(
            label: 'listing.f_view'.tr(),
            clearable: true,
            value: _d.view,
            options: [
              for (final v in ListingDraft.views) (v, 'listing.v_$v'.tr()),
            ],
            onChanged: (v) => _set('view', () => _d.view = v),
          ),
        ];
      case CardField.delivery:
        return [
          ChipPicker(
            label: 'listing.f_delivery'.tr(),
            cols: 2,
            clearable: true,
            value: _d.delivery,
            options: [
              for (final x in ListingDraft.deliveries)
                (
                  x,
                  x == 'ready'
                      ? 'listing.d_ready'.tr()
                      : (x == '2029' ? '2029+' : x),
                ),
            ],
            onChanged: (v) => _set('delivery', () => _d.delivery = v),
          ),
        ];
      case CardField.price:
        return [
          ListingInput(
            fieldKey: const Key('field-price'),
            label: 'listing.f_price'.tr(),
            value: _d.price,
            prefix: 'EGP',
            numeric: true,
            onChanged: (v) => _set('price', () => _d.price = v),
          ),
        ];
      case CardField.payment:
        return [
          ChipPicker(
            label: 'listing.f_payment'.tr(),
            cols: 2,
            value: _d.payment,
            options: [
              ('cash', 'listing.cash'.tr()),
              ('installments', 'listing.installments'.tr()),
            ],
            onChanged: (v) {
              _set('payment', () => _d.payment = v ?? 'cash');
              widget.onPayment();
            },
          ),
          if (_d.payment == 'installments') ...[
            const SizedBox(height: 16),
            ListingInput(
              fieldKey: const Key('field-down'),
              label: 'listing.f_down'.tr(),
              value: _d.down,
              suffix: '%',
              numeric: true,
              onChanged: (v) {
                _set('down', () => _d.down = v);
                widget.onPayment();
              },
            ),
            const SizedBox(height: 16),
            ListingInput(
              fieldKey: const Key('field-years'),
              label: 'listing.f_over'.tr(),
              value: _d.years,
              suffix: 'listing.years'.tr(),
              numeric: true,
              onChanged: (v) {
                _set('years', () => _d.years = v);
                widget.onPayment();
              },
            ),
          ],
        ];
      case CardField.compound:
        return const [];
    }
  }
}
