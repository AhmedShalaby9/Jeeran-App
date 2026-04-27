import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_filter_params.dart';
import '../bloc/properties_bloc.dart';
import '../bloc/properties_event.dart';
import '../bloc/properties_state.dart';
import '../widgets/properties_shimmer.dart';
import '../widgets/property_card.dart';

class PropertiesScreen extends StatefulWidget {
  final PropertyFilterParams params;
  const PropertiesScreen({super.key, required this.params});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  late final PropertiesBloc _bloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = sl<PropertiesBloc>()..add(FetchPropertiesEvent(widget.params));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.9) {
      _bloc.add(const LoadMorePropertiesEvent());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('properties.title'.tr()),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'properties.reset_filters'.tr(),
              onPressed: () => _bloc.add(const ResetFiltersEvent()),
            ),
          ],
        ),
        body: BlocBuilder<PropertiesBloc, PropertiesState>(
          builder: (context, state) {
            if (state is PropertiesLoading) {
              return const PropertiesShimmer();
            }
            if (state is PropertiesError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => _bloc.add(FetchPropertiesEvent(widget.params)),
              );
            }
            if (state is PropertiesLoaded) {
              return _buildList(
                state.properties,
                params: state.params,
                loadingMore: false,
              );
            }
            if (state is PropertiesLoadingMore) {
              return _buildList(
                state.currentProperties,
                params: state.params,
                loadingMore: true,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildList(
    List<Property> properties, {
    required PropertyFilterParams params,
    required bool loadingMore,
  }) {
    final activeChips = _buildActiveFilterChips(context, params);
    if (properties.isEmpty) {
      return Column(
        children: [
          if (activeChips.isNotEmpty) _ActiveFiltersWrap(chips: activeChips),
          Expanded(
            child: Center(
              child: Text(
                'properties.no_results'.tr(),
                style: const TextStyle(color: AppColors.grey, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    final listBody = ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: properties.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= properties.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PropertyCard.horizontalCard(
            property: properties[index],
            onTap: () {},
          ),
        );
      },
    );

    if (activeChips.isEmpty) return listBody;

    return Column(
      children: [
        _ActiveFiltersWrap(chips: activeChips),
        Expanded(child: listBody),
      ],
    );
  }

  List<Widget> _buildActiveFilterChips(
    BuildContext context,
    PropertyFilterParams params,
  ) {
    final chips = <Widget>[];

    if (params.q != null && params.q!.isNotEmpty) {
      chips.add(
        _FilterChip(
          label: params.q!,
          onRemove: () => _applyParams(params.copyWith(q: null)),
        ),
      );
    }

    if (params.status != null) {
      chips.add(
        _FilterChip(
          label: 'status.${params.status}'.tr(),
          onRemove: () => _applyParams(params.copyWith(status: null)),
        ),
      );
    }

    if (params.type != null) {
      chips.add(
        _FilterChip(
          label: 'type.${params.type}'.tr(),
          onRemove: () => _applyParams(params.copyWith(type: null)),
        ),
      );
    }

    if (params.projectId != null) {
      chips.add(
        _FilterChip(
          label: '${'search.filters.project'.tr()} #${params.projectId}',
          onRemove: () => _applyParams(params.copyWith(projectId: null)),
        ),
      );
    }

    if (params.minPrice != null || params.maxPrice != null) {
      final label = '${params.minPrice ?? ''} — ${params.maxPrice ?? ''}';
      chips.add(
        _FilterChip(
          label: label,
          onRemove: () =>
              _applyParams(params.copyWith(minPrice: null, maxPrice: null)),
        ),
      );
    }

    if (params.bedrooms != null) {
      chips.add(
        _FilterChip(
          label: '${params.bedrooms} ${'search.filters.bedrooms'.tr()}',
          onRemove: () => _applyParams(params.copyWith(bedrooms: null)),
        ),
      );
    }

    if (params.isFeatured == true) {
      chips.add(
        _FilterChip(
          label: 'search.filters.featured_only'.tr(),
          onRemove: () => _applyParams(params.copyWith(isFeatured: null)),
        ),
      );
    }

    if (params.sort != null) {
      chips.add(
        _FilterChip(
          label: 'sort.${params.sort}'.tr(),
          onRemove: () => _applyParams(params.copyWith(sort: null)),
        ),
      );
    }

    if (params.order != null) {
      chips.add(
        _FilterChip(
          label: 'order.${params.order}'.tr(),
          onRemove: () => _applyParams(params.copyWith(order: null)),
        ),
      );
    }

    return chips;
  }

  void _applyParams(PropertyFilterParams params) {
    _bloc.add(FetchPropertiesEvent(params));
  }
}

class _ActiveFiltersWrap extends StatelessWidget {
  final List<Widget> chips;
  const _ActiveFiltersWrap({required this.chips});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'properties.active_filters'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('actions.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
