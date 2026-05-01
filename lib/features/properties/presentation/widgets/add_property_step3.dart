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
      ],
    );
  }
}
