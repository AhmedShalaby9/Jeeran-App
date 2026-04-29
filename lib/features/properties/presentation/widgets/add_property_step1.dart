import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'add_property_form.dart';

class AddPropertyStep1 extends StatefulWidget {
  final AddPropertyForm form;
  final VoidCallback onChanged;

  const AddPropertyStep1({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  State<AddPropertyStep1> createState() => _AddPropertyStep1State();
}

class _AddPropertyStep1State extends State<AddPropertyStep1> {
  static const _purposes = ['For Sale', 'For Rent'];

  static const _types = [
    _PropertyType('apartment', 'Apartment', 'Flats, studios, penthouses', Icons.apartment_rounded),
    _PropertyType('villa', 'Villa', 'Standalone & townhouses', Icons.house_rounded),
    _PropertyType('office', 'Office', 'Commercial spaces', Icons.business_center_rounded),
    _PropertyType('land', 'Land', 'Plots & agricultural', Icons.landscape_rounded),
    _PropertyType('retail', 'Retail', 'Shops & showrooms', Icons.storefront_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you listing?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the property type and purpose.',
          style: TextStyle(fontSize: 15, color: AppColors.inkSub, height: 1.4),
        ),
        const SizedBox(height: 24),

        // ── Purpose toggle ───────────────────────────────────────
        const WizardLabel('Purpose', required: true),
        Row(
          children: _purposes.map((p) {
            final active = widget.form.purpose == p;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: p == _purposes.first ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    widget.form.purpose = p;
                    widget.onChanged();
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 48,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),

        // ── Property type list ───────────────────────────────────
        const WizardLabel('Property type', required: true),
        ...List.generate(_types.length, (i) {
          final t = _types[i];
          final active = widget.form.propertyType == t.id;
          return Padding(
            padding: EdgeInsets.only(bottom: i < _types.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () {
                widget.form.propertyType = t.id;
                widget.onChanged();
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.hairline,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        t.icon,
                        size: 20,
                        color: active ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Label + sub
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Radio circle
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: active ? AppColors.primary : const Color(0xFFD5DAE2),
                          width: 2,
                        ),
                      ),
                      child: active
                          ? const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PropertyType {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  const _PropertyType(this.id, this.label, this.subtitle, this.icon);
}
