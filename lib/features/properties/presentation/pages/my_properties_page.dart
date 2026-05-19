import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_filter_params.dart';
import '../../domain/repositories/property_repository.dart';
import '../bloc/my_properties_bloc.dart';
import '../bloc/properties_event.dart';
import '../bloc/properties_state.dart';
import '../widgets/properties_shimmer.dart';
import '../widgets/property_card.dart';
import 'property_details_page.dart';

class MyPropertiesPage extends StatelessWidget {
  const MyPropertiesPage({super.key});

  static Future<void> push(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyPropertiesPage()),
      );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<MyPropertiesBloc>()),
        BlocProvider(
          create: (_) =>
              sl<SubscriptionBloc>()..add(const FetchMySubscriptionEvent()),
        ),
      ],
      child: const _MyPropertiesView(),
    );
  }
}

class _MyPropertiesView extends StatefulWidget {
  const _MyPropertiesView();

  @override
  State<_MyPropertiesView> createState() => _MyPropertiesViewState();
}

class _MyPropertiesViewState extends State<_MyPropertiesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  static const _tabs = [null, true, false];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _fetch(null);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _fetch(_tabs[_tabController.index]);
  }

  void _fetch(bool? isApproved) {
    context.read<MyPropertiesBloc>().add(
          FetchPropertiesEvent(PropertyFilterParams(isApproved: isApproved)),
        );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.9) {
      context.read<MyPropertiesBloc>().add(const LoadMorePropertiesEvent());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('my_properties.title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.inkSub,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'my_properties.all'.tr()),
            Tab(text: 'my_properties.approved'.tr()),
            Tab(text: 'my_properties.pending'.tr()),
          ],
        ),
      ),
      body: BlocBuilder<MyPropertiesBloc, PropertiesState>(
        builder: (context, state) {
          if (state is PropertiesLoading) {
            return const PropertiesShimmer();
          }
          if (state is PropertiesError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => _fetch(_tabs[_tabController.index]),
            );
          }

          final properties = switch (state) {
            PropertiesLoaded s => s.properties,
            PropertiesLoadingMore s => s.currentProperties,
            _ => null,
          };

          if (properties == null) return const SizedBox.shrink();
          if (properties.isEmpty) return _EmptyView();

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: properties.length + (state is PropertiesLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == properties.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              final property = properties[index];
              final subState = context.read<SubscriptionBloc>().state;
              final remainingFeatured = subState is MySubscriptionLoaded
                  ? subState.subscription.remainingFeatured
                  : 0;
              return _PropertyCardWithFeaturedToggle(
                property: property,
                remainingFeatured: remainingFeatured,
                onFeaturedToggled: () => _fetch(_tabs[_tabController.index]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailsPage(property: property),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Property card with featured toggle ───────────────────────

class _PropertyCardWithFeaturedToggle extends StatefulWidget {
  final Property property;
  final int remainingFeatured;
  final VoidCallback onFeaturedToggled;
  final VoidCallback onTap;

  const _PropertyCardWithFeaturedToggle({
    required this.property,
    required this.remainingFeatured,
    required this.onFeaturedToggled,
    required this.onTap,
  });

  @override
  State<_PropertyCardWithFeaturedToggle> createState() =>
      _PropertyCardWithFeaturedToggleState();
}

class _PropertyCardWithFeaturedToggleState
    extends State<_PropertyCardWithFeaturedToggle> {
  bool _loading = false;

  Future<void> _toggle() async {
    final newValue = !widget.property.isFeatured;

    // Disallow turning ON when no slots remain
    if (newValue && widget.remainingFeatured <= 0) {
      AppSnackbar.show(
        context,
        message: 'No featured slots remaining in your subscription.',
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.inkSub,
      );
      return;
    }

    setState(() => _loading = true);
    final result = await sl<PropertyRepository>()
        .updateProperty(widget.property.id, {'is_featured': newValue});
    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => AppSnackbar.show(
        context,
        message: 'Failed to update listing.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.danger,
      ),
      (_) {
        AppSnackbar.show(
          context,
          message: newValue
              ? 'Listing is now featured!'
              : 'Listing removed from featured.',
          icon: newValue ? Icons.star_rounded : Icons.star_border_rounded,
          iconColor: newValue ? const Color(0xFFF59E0B) : AppColors.inkSub,
        );
        widget.onFeaturedToggled();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canToggleOn =
        widget.property.isFeatured || widget.remainingFeatured > 0;

    return Stack(
      children: [
        PropertyCard.horizontalCard(
          property: widget.property,
          onTap: widget.onTap,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _loading ? null : _toggle,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: widget.property.isFeatured
                    ? const Color(0xFFF59E0B)
                    : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      widget.property.isFeatured
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color: widget.property.isFeatured
                          ? Colors.white
                          : canToggleOn
                              ? AppColors.inkSub
                              : AppColors.inkMute,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.home_work_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'my_properties.empty_title'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'my_properties.empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSub, height: 1.5),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.inkMute),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 14, color: AppColors.inkSub)),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: Text('my_properties.retry'.tr())),
        ],
      ),
    );
  }
}
