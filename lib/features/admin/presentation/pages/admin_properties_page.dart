import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/entities/property_filter_params.dart';
import '../../../properties/presentation/bloc/properties_bloc.dart';
import '../../../properties/presentation/bloc/properties_event.dart';
import '../../../properties/presentation/bloc/properties_state.dart';
import 'admin_property_detail_page.dart';

class AdminPropertiesPage extends StatelessWidget {
  const AdminPropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PropertiesBloc>()
        ..add(const FetchPropertiesEvent(
          PropertyFilterParams(isApproved: false, perPage: 50),
        )),
      child: const _AdminPropertiesView(),
    );
  }
}

class _AdminPropertiesView extends StatefulWidget {
  const _AdminPropertiesView();

  @override
  State<_AdminPropertiesView> createState() => _AdminPropertiesViewState();
}

class _AdminPropertiesViewState extends State<_AdminPropertiesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchForTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchForTab(int index) {
    final isApproved = index == 1; // tab 0 = pending, tab 1 = approved
    context.read<PropertiesBloc>().add(
          FetchPropertiesEvent(
            PropertyFilterParams(
              isApproved: isApproved,
              perPage: 50,
            ),
          ),
        );
  }

  void _refresh(BuildContext context) {
    _fetchForTab(_tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('admin.properties'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'admin.tab_pending'.tr()),
            Tab(text: 'admin.tab_approved'.tr()),
          ],
        ),
      ),
      body: BlocConsumer<PropertiesBloc, PropertiesState>(
        listener: (context, state) {
          if (state is PropertyActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('admin.action_success'.tr())),
            );
            _refresh(context);
          } else if (state is PropertyActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is PropertiesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PropertiesError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _refresh(context),
                    child: Text('actions.retry'.tr()),
                  ),
                ],
              ),
            );
          }
          if (state is PropertiesLoaded) {
            if (state.properties.isEmpty) {
              return Center(child: Text('admin.no_properties'.tr()));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final property = state.properties[index];
                final bloc = context.read<PropertiesBloc>();
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: AdminPropertyDetailPage(property: property),
                        ),
                      ),
                    );
                    // Refresh list when returning from detail
                    if (context.mounted) _refresh(context);
                  },
                  child: _PropertyAdminTile(property: property),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PropertyAdminTile extends StatelessWidget {
  final Property property;

  const _PropertyAdminTile({required this.property});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: property.coverImage != null
                    ? Image.network(
                        property.coverImage!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.localTitle(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (property.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${property.price} ${'currency'.tr()}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (property.state != null || property.country != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [property.state, property.country]
                            .whereType<String>()
                            .join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkMute,
                        ),
                      ),
                    ],
                    if (property.rejectionReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${'admin.rejection_reason'.tr()}: ${property.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkMute),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.tagPrimaryBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.home_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}
