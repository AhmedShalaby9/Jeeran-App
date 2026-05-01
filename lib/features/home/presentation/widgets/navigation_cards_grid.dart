import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../properties/domain/entities/property_filter_params.dart';
import '../../../properties/presentation/pages/properties_screen.dart';
import 'navigation_icon_card.dart';

class NavigationCardsGrid extends StatelessWidget {
  const NavigationCardsGrid({super.key});

  void _navigate(BuildContext context, PropertyFilterParams params) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PropertiesScreen(params: params)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero ,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
       childAspectRatio: 1.6,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        buildNavigationCard(
          title: 'Jeeran Properties',
          icon: Icons.location_city_outlined,
          onTap: () => _navigate(context, const PropertyFilterParams()),
        ),
        buildNavigationCard(
          title: 'status.for_sale'.tr(),
          icon: Icons.sell_outlined,
          onTap: () => _navigate(context, const PropertyFilterParams(status: 'for_sale')),
        ),
        buildNavigationCard(
          title: 'status.for_rent'.tr(),
          icon: Icons.key_outlined,
          onTap: () => _navigate(context, const PropertyFilterParams(status: 'for_rent')),
        ),
        buildNavigationCard(
          title: 'status.for_rent_furnished'.tr(),
          icon: Icons.chair_outlined,
          onTap: () => _navigate(context, const PropertyFilterParams(status: 'for_rent_furnished')),
        ),
      ],
    );
  }
}
