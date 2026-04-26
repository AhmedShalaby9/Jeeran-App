import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/city.dart';
import '../bloc/cities_bloc.dart';
import '../bloc/cities_event.dart';
import '../bloc/cities_state.dart';

class ExploreCitiesWidget extends StatelessWidget {
  final String? title;
  const ExploreCitiesWidget({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CitiesBloc>()..add(const FetchCitiesEvent()),
      child: _ExploreCitiesView(title: title),
    );
  }
}

class _ExploreCitiesView extends StatefulWidget {
  final String? title;
  const _ExploreCitiesView({this.title});

  @override
  State<_ExploreCitiesView> createState() => _ExploreCitiesViewState();
}

class _ExploreCitiesViewState extends State<_ExploreCitiesView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;
  double _scrollPosition = 0;
  bool _scrollingForward = true;

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isUserScrolling && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (_scrollingForward) {
          _scrollPosition += 0.5;
          if (_scrollPosition >= maxScroll) {
            _scrollPosition = maxScroll;
            _scrollingForward = false;
          }
        } else {
          _scrollPosition -= 0.5;
          if (_scrollPosition <= 0) {
            _scrollPosition = 0;
            _scrollingForward = true;
          }
        }
        _scrollController.jumpTo(_scrollPosition);
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CitiesBloc, CitiesState>(
      listener: (context, state) {
        if (state is CitiesLoaded && state.cities.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
        }
      },
      builder: (context, state) {
        if (state is CitiesLoading) return _buildShimmer();
        if (state is CitiesLoaded && state.cities.isNotEmpty) {
          return _buildContent(state.cities);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(List<City> cities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.title ?? 'Explore Cities',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserScrolling = true;
              } else if (notification is ScrollEndNotification) {
                _isUserScrolling = false;
                _scrollPosition = _scrollController.offset;
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cities.length,
              itemBuilder: (_, i) => _CityCard(city: cities[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 20,
            width: 140,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Center(child: AppLoading.cupertino()),
        ),
      ],
    );
  }
}

class _CityCard extends StatelessWidget {
  final City city;
  const _CityCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            city.image != null && city.image!.isNotEmpty
                ? AppImage.network(city.image!, fit: BoxFit.cover)
                : Container(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.location_city, size: 40, color: AppColors.primary),
                  ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                    ),
                  ),
                  if (city.propertiesCount > 0)
                    Text(
                      '${city.propertiesCount} properties',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
