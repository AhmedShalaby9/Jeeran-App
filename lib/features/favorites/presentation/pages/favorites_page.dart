import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/entities/property_filter_params.dart';
import '../../../properties/presentation/pages/properties_screen.dart';
import '../../../properties/presentation/widgets/property_card.dart';
import '../../../properties/presentation/pages/property_details_page.dart';
import '../bloc/favorites_bloc.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // Defer until after the first frame so the BlocProvider is in context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FavoritesBloc>().add(const FetchFavoritesEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('favorites.title'.tr())),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FavoritesLoaded) {
            if (state.properties.isEmpty) return const _EmptyFavorites();
            return _FavoritesList(properties: state.properties);
          }
          if (state is FavoritesError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<FavoritesBloc>()
                  .add(const FetchFavoritesEvent()),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final List<Property> properties;
  const _FavoritesList({required this.properties});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: properties.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard.horizontalCard(
          property: property,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailsPage(property: property),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

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
            child: Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'favorites.empty_title'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'favorites.empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PropertiesScreen(params: PropertyFilterParams()),
              ),
            ),
            icon: const Icon(Icons.search),
            label: Text('favorites.browse'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 14, color: AppColors.grey)),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
