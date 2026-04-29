import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
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

  static const _furnishings = ['Unfurnished', 'Semi-furnished', 'Furnished'];

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
        const Text(
          'Property details',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'The essentials buyers search for.',
          style: TextStyle(fontSize: 15, color: AppColors.inkSub, height: 1.4),
        ),
        const SizedBox(height: 24),

        // ── Price ────────────────────────────────────────────────
        const WizardLabel('Price', required: true),
        _InputWithSuffix(
          controller: _priceCtrl,
          hint: '0',
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
        _InputWithSuffix(
          controller: _sizeCtrl,
          hint: '0',
          suffix: 'm²',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            widget.form.size = v;
            widget.onChanged();
          },
        ),
        const SizedBox(height: 20),

        // ── Counters card ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              _CounterRow(
                icon: Icons.bed_outlined,
                label: 'Bedrooms',
                value: widget.form.bedrooms,
                divider: true,
                onChanged: (v) => _update(() => widget.form.bedrooms = v),
              ),
              _CounterRow(
                icon: Icons.bathtub_outlined,
                label: 'Bathrooms',
                value: widget.form.bathrooms,
                divider: true,
                onChanged: (v) => _update(() => widget.form.bathrooms = v),
              ),
              _CounterRow(
                icon: Icons.directions_car_outlined,
                label: 'Parking spots',
                value: widget.form.parkingSpots,
                divider: false,
                onChanged: (v) => _update(() => widget.form.parkingSpots = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Furnishing chips ─────────────────────────────────────
        const WizardLabel('Furnishing'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _furnishings.map((f) {
            return WizardChip(
              label: f,
              active: widget.form.furnishing == f,
              onTap: () => _update(() {
                widget.form.furnishing =
                    widget.form.furnishing == f ? null : f;
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────

class _InputWithSuffix extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _InputWithSuffix({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.hairline),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(fontSize: 15, color: AppColors.inkMute),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        Text(
          suffix,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSub,
          ),
        ),
      ],
    ),
  );
}

class _CounterRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final bool divider;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.divider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: divider
          ? const Border(
              bottom: BorderSide(color: AppColors.hairline),
            )
          : null,
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.inkSub),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
        WizardCounter(
          value: value,
          min: 0,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
