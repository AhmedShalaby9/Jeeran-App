import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';

class PropertyDetailsTab extends StatelessWidget {
  final Property property;

  const PropertyDetailsTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('property_details.property_type'.tr(), property.propertyType),
      ('property_details.area'.tr(), property.size != null ? '${property.size} m²' : null),
      ('property_details.bedrooms'.tr(), property.bedrooms?.toString()),
      ('property_details.bathrooms'.tr(), property.bathrooms?.toString()),
      ('property_details.purpose'.tr(), property.propertyStatus),
      ('property_details.reference'.tr(), property.legacyCode),
      ('property_details.country'.tr(), property.country),
      ('property_details.city_state'.tr(), property.state),
    ].where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No details available.',
            style: TextStyle(color: AppColors.inkMute),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: List.generate(rows.length, (i) {
          final last = i == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].$1,
                    style: const TextStyle(fontSize: 14, color: AppColors.inkSub),
                  ),
                ),
                Text(
                  rows[i].$2!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
