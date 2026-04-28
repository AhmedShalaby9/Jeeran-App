import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';
import 'property_similar_section.dart';
import 'property_widgets.dart';

class PropertyOverviewTab extends StatelessWidget {
  final Property property;

  const PropertyOverviewTab({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (property.content?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              property.content!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkSub,
                height: 1.65,
              ),
            ),
          ),
        Row(
          children: [
            if (property.legacyCode?.isNotEmpty == true) ...[
              Expanded(
                child: InfoChip(label: 'REF', value: property.legacyCode!),
              ),
              const SizedBox(width: 8),
            ],
            if (property.publishedAt?.isNotEmpty == true)
              Expanded(
                child: InfoChip(
                  label: 'YEAR',
                  value: property.publishedAt!.length >= 4
                      ? property.publishedAt!.substring(0, 4)
                      : property.publishedAt!,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        PropertySimilarSection(property: property),
      ],
    );
  }
}
