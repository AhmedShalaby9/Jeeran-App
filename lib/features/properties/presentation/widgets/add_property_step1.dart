import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/enums/property_enums.dart';
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
  static const _typeIcons = <PropertyType, IconData>{
    PropertyType.villa: Icons.house_rounded,
    PropertyType.apartment: Icons.apartment_rounded,
    PropertyType.chalet: Icons.cabin_rounded,
    PropertyType.marinaApartment: Icons.water_rounded,
    PropertyType.clinic: Icons.local_hospital_rounded,
    PropertyType.office: Icons.business_center_rounded,
    PropertyType.shop: Icons.storefront_rounded,
    PropertyType.land: Icons.landscape_rounded,
    PropertyType.studio: Icons.meeting_room_rounded,
    PropertyType.duplex: Icons.layers_rounded,
  };

  static const _typeSubtitles = <PropertyType, String>{
    PropertyType.villa: 'Standalone & townhouses',
    PropertyType.apartment: 'Flats, penthouses',
    PropertyType.chalet: 'Holiday & coastal',
    PropertyType.marinaApartment: 'Waterfront units',
    PropertyType.clinic: 'Medical spaces',
    PropertyType.office: 'Commercial offices',
    PropertyType.shop: 'Shops & showrooms',
    PropertyType.land: 'Plots & agricultural',
    PropertyType.studio: 'Open-plan units',
    PropertyType.duplex: 'Two-floor units',
  };

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
          'What are you listing?',
          subtitle: 'Choose the type and status of the property.',
        ),

        // ── Property status ──────────────────────────────────────
        const WizardLabel('Listing status', required: true),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PropertyStatus.options.map((s) {
            return WizardChip(
              label: s.label(),
              active: widget.form.propertyStatus == s,
              onTap: () => _update(() => widget.form.propertyStatus = s),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),

        // ── Property type list ───────────────────────────────────
        const WizardLabel('Property type', required: true),
        ...PropertyType.options.map((t) {
          final active = widget.form.propertyType == t;
          final isLast = t == PropertyType.options.last;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: GestureDetector(
              onTap: () => _update(() => widget.form.propertyType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        _typeIcons[t] ?? Icons.home_rounded,
                        size: 20,
                        color: active ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.label(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _typeSubtitles[t] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
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
