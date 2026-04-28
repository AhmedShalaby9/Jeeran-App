import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';
import 'property_widgets.dart';

class PropertyAgentTab extends StatelessWidget {
  final Property property;
  final String Function(String?) initials;

  const PropertyAgentTab({
    super.key,
    required this.property,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final name = property.agentName;
    if (name == null || name.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No agent info available.',
            style: TextStyle(color: AppColors.inkMute),
          ),
        ),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tagPrimaryBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.agentGradientEnd],
                  ),
                ),
                child: Center(
                  child: Text(
                    initials(name),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Agent',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSub),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (property.agentMobile?.isNotEmpty == true)
                    ContactCircle(
                      color: AppColors.primary,
                      icon: Icons.phone_rounded,
                      onTap: () {},
                    ),
                  if (property.agentWhatsapp?.isNotEmpty == true) ...[
                    const SizedBox(width: 8),
                    ContactCircle(
                      color: AppColors.whatsapp,
                      icon: Icons.chat_rounded,
                      onTap: () {},
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.inkSub,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'This listing is managed by '),
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const TextSpan(
                  text: '. Contact them directly for viewings, pricing, or any questions about the property.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
