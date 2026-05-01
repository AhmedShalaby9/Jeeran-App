import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';
import 'property_widgets.dart';

class PropertyPriceCard extends StatelessWidget {
  final Property property;
  final String Function(String?) formatPrice;

  const PropertyPriceCard({
    super.key,
    required this.property,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final hasStats = property.bedrooms != null ||
        property.bathrooms != null ||
        (property.size != null && property.size!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (property.propertyStatus?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          property.propertyStatus!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    Text(
                      property.localTitle(context.locale.languageCode),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.1,
                        color: AppColors.ink,
                      ),
                    ),
                    if (property.project?.name != null || property.state?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: AppColors.inkSub,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                [property.project?.name, property.state]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkSub,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (property.price?.isNotEmpty == true)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.tagPrimaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPrice(property.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'currency'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (hasStats) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: AppColors.hairline),
            const SizedBox(height: 14),
            Row(
              children: [
                if (property.bedrooms != null) ...[
                  StatPill(icon: Icons.bed_rounded, label: ' Beds'),
                  const SizedBox(width: 6),
                ],
                if (property.bathrooms != null) ...[
                  StatPill(icon: Icons.bathtub_rounded, label: ' Baths'),
                  const SizedBox(width: 6),
                ],
                if (property.size?.isNotEmpty == true)
                  StatPill(icon: Icons.crop_square_rounded, label: ' m²'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
