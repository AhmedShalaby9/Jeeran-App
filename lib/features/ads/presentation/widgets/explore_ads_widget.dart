import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/ad.dart';
import '../bloc/ads_bloc.dart';
import '../bloc/ads_state.dart';
import 'ad_card.dart';

class ExploreAdsWidget extends StatelessWidget {
  const ExploreAdsWidget({super.key});

  @override
  Widget build(BuildContext context) => const _ExploreAdsView();
}

class _ExploreAdsView extends StatefulWidget {
  const _ExploreAdsView();

  @override
  State<_ExploreAdsView> createState() => _ExploreAdsViewState();
}

class _ExploreAdsViewState extends State<_ExploreAdsView> {
  final _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;
  double _scrollPosition = 0;
  bool _scrollingForward = true;
  bool _scrollStarted = false;

  void _startAutoScroll() {
    if (_scrollStarted) return;
    _scrollStarted = true;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isUserScrolling && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) return;
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

  void _scheduleAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdsBloc, AdsState>(
      listener: (context, state) {
        if (state is AdsLoaded && state.ads.isNotEmpty) {
          _scrollStarted = false; // allow restart on reload
          _scheduleAutoScroll();
        }
      },
      builder: (context, state) {
        if (state is AdsLoading) {
          return SizedBox(
            height: 200,
            child: Center(child: AppLoading.cupertino()),
          );
        }
        if (state is AdsLoaded && state.ads.isNotEmpty) {
          _scheduleAutoScroll(); // also triggers if state was already loaded on mount
          return _buildList(state.ads);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildList(List<Ad> ads) {
    return SizedBox(
      height: 200,
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
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemCount: ads.length,
          itemBuilder: (_, i) =>
              SizedBox(width: 240, child: AdCard(ad: ads[i])),
        ),
      ),
    );
  }
}
