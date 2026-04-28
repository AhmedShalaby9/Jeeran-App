import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_loading.dart';
import '../bloc/properties_bloc.dart';
import '../bloc/properties_state.dart';
import 'property_card.dart';
import '../pages/property_details_page.dart';

class FeaturedPropertiesWidget extends StatelessWidget {
  const FeaturedPropertiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeaturedPropertiesView();
  }
}

class _FeaturedPropertiesView extends StatelessWidget {
  const _FeaturedPropertiesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesBloc, PropertiesState>(
      builder: (context, state) {
        if (state is PropertiesLoading) {
          return SizedBox(
            height: 320,
            child: Center(child: AppLoading.cupertino()),
          );
        }
        if (state is PropertiesLoaded && state.properties.isNotEmpty) {
          return _buildList(state.properties);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildList(List<dynamic> properties) {
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemCount: properties.length,
        itemBuilder: (context, i) => PropertyCard.featured(
          property: properties[i],
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsPage(property: properties[i]))),
        ),
      ),
    );
  }
}
