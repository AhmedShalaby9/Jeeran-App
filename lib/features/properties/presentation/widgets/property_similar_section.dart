import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';
import '../bloc/property_similar_bloc.dart';
import '../bloc/property_similar_event.dart';
import '../bloc/property_similar_state.dart';
import '../pages/property_details_page.dart';
import 'property_widgets.dart';

class PropertySimilarSection extends StatefulWidget {
  final Property property;

  const PropertySimilarSection({super.key, required this.property});

  @override
  State<PropertySimilarSection> createState() => _PropertySimilarSectionState();
}

class _PropertySimilarSectionState extends State<PropertySimilarSection> {
  late final PropertySimilarBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<PropertySimilarBloc>()
      ..add(FetchPropertySimilarEvent(widget.property.id));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'property_details.similar_properties'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: BlocBuilder<PropertySimilarBloc, PropertySimilarState>(
              builder: (context, state) {
                if (state is PropertySimilarLoading) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }
                if (state is PropertySimilarError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          color: AppColors.inkSub,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                if (state is PropertySimilarLoaded) {
                  if (state.properties.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No similar properties found.',
                          style: TextStyle(
                            color: AppColors.inkSub,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.properties.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailsPage(
                            property: state.properties[index],
                          ),
                        ),
                      ),
                      child: SimilarPropertyCard(
                        property: state.properties[index],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
