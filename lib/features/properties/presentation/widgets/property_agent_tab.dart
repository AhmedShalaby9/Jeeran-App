import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_filter_params.dart';
import '../bloc/properties_bloc.dart';
import '../bloc/properties_event.dart';
import '../bloc/properties_state.dart';
import '../pages/properties_screen.dart';
import '../pages/property_details_page.dart';
import 'property_card.dart';
import 'property_widgets.dart';

class PropertyAgentTab extends StatefulWidget {
  final Property property;
  final String Function(String?) initials;

  const PropertyAgentTab({
    super.key,
    required this.property,
    required this.initials,
  });

  @override
  State<PropertyAgentTab> createState() => _PropertyAgentTabState();
}

class _PropertyAgentTabState extends State<PropertyAgentTab> {
  late final PropertiesBloc _bloc;

  Future<void> _call() async {
    final number = widget.property.agentMobile;
    if (number == null || number.isEmpty) return;
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final number = widget.property.agentWhatsapp;
    if (number == null || number.isEmpty) return;
    final clean = number.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _bloc = sl<PropertiesBloc>();
    final name = widget.property.agentName;
    if (name != null && name.isNotEmpty) {
      _bloc.add(
        FetchPropertiesEvent(
          PropertyFilterParams(agentName: name, perPage: 10),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.property.agentName;
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

    return BlocProvider.value(
      value: _bloc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent info card
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
                      widget.initials(name),
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
                      Text(
                        'property_details.agent_label'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSub,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (widget.property.agentMobile?.isNotEmpty == true)
                      ContactCircle(
                        color: AppColors.primary,
                        icon: const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
                        onTap: _call,
                      ),
                    if (widget.property.agentWhatsapp?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      ContactCircle(
                        color: AppColors.whatsapp,
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.white),
                        onTap: _whatsapp,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Disclaimer
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
                  TextSpan(
                    text: 'property_details.managed_by'.tr(),
                  ),
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  TextSpan(
                    text: 'property_details.contact_note'.tr(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Agent properties header
          Text(
            'property_details.more_from_agent'.tr(namedArgs: {'agent': name}),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          // Agent properties list
          BlocBuilder<PropertiesBloc, PropertiesState>(
            builder: (context, state) {
              if (state is PropertiesLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }
              if (state is PropertiesError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
              if (state is PropertiesLoaded) {
                final others = state.properties
                    .where((p) => p.id != widget.property.id)
                    .toList();
                if (others.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'property_details.no_agent_properties'.tr(),
                      style: const TextStyle(
                        color: AppColors.inkSub,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...others.take(5).map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PropertyCard.horizontalCard(
                          property: p,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PropertyDetailsPage(property: p),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (others.length > 5 || !state.hasReachedMax)
                      _ViewAllButton(agentName: name),
                    const SizedBox(height: 10),

                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final String agentName;
  const _ViewAllButton({required this.agentName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertiesScreen(
            params: PropertyFilterParams(agentName: agentName),
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'property_details.see_all'.tr(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
