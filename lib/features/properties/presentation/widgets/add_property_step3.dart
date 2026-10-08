import 'package:flutter/material.dart';
import 'add_property_form.dart';

class AddPropertyStep3 extends StatefulWidget {
  final AddPropertyForm form;
  final VoidCallback onChanged;

  const AddPropertyStep3({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  State<AddPropertyStep3> createState() => _AddPropertyStep3State();
}

class _AddPropertyStep3State extends State<AddPropertyStep3> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _sizeCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.form.price);
    _sizeCtrl = TextEditingController(text: widget.form.size);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  static const _finishings = [
    ('fully_finished', 'Fully finished'),
    ('semi_finished', 'Semi-finished'),
    ('core_shell', 'Core & shell'),
    ('furnished', 'Furnished'),
  ];
  static const _payments = [
    ('cash', 'Cash'),
    ('installments', 'Installments'),
    ('mortgage', 'Mortgage eligible'),
  ];
  static const _amenities = [
    ('sea_view', 'Sea view'),
    ('pool_view', 'Pool view'),
    ('private_garden', 'Private garden'),
    ('roof', 'Roof'),
    ('golf_view', 'Golf view'),
    ('beach_access', 'Beach access'),
    ('corner_unit', 'Corner unit'),
    ('parking', 'Parking'),
  ];

  void _toggle(Set<String> set, String v) =>
      set.contains(v) ? set.remove(v) : set.add(v);

  void _update(VoidCallback fn) {
    fn();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepTitle(
          'Property details',
          subtitle: 'The essentials buyers and renters search for.',
        ),

        // ── Price ────────────────────────────────────────────────
        const WizardLabel('Price', required: true),
        WizardInput(
          placeholder: '0',
          value: widget.form.price,
          suffix: 'EGP',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            widget.form.price = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 16),

        // ── Area ─────────────────────────────────────────────────
        const WizardLabel('Area', required: true),
        WizardInput(
          placeholder: '0',
          value: widget.form.size,
          suffix: 'm²',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            widget.form.size = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 20),

        // ── Counters ──────────────────────────────────────────────
        WizardCounterRow(
          label: 'Bedrooms',
          hint: 'Number of bedrooms',
          value: widget.form.bedrooms,
          min: 1,
          onChanged: (v) => _update(() => widget.form.bedrooms = v),
        ),
        const SizedBox(height: 10),
        WizardCounterRow(
          label: 'Bathrooms',
          hint: 'Number of bathrooms',
          value: widget.form.bathrooms,
          min: 1,
          onChanged: (v) => _update(() => widget.form.bathrooms = v),
        ),
        const SizedBox(height: 24),

        // ── Optional details: left empty, the compound's apply ───
        const WizardLabel('Finishing'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in _finishings)
              WizardChip(
                label: f.$2,
                active: widget.form.finishing == f.$1,
                onTap: () => _update(
                  () => widget.form.finishing = widget.form.finishing == f.$1
                      ? null
                      : f.$1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const WizardLabel('Payment'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _payments)
              WizardChip(
                label: p.$2,
                active: widget.form.payment.contains(p.$1),
                onTap: () => _update(() => _toggle(widget.form.payment, p.$1)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const WizardLabel('Amenities'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in _amenities)
              WizardChip(
                label: a.$2,
                active: widget.form.amenities.contains(a.$1),
                onTap: () =>
                    _update(() => _toggle(widget.form.amenities, a.$1)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Optional — anything you leave out is taken from the compound.',
          style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3)),
        ),
      ],
    );
  }
}
