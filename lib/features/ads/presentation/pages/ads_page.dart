import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../bloc/ads_bloc.dart';
import '../bloc/ads_event.dart';
import '../bloc/ads_state.dart';
import '../widgets/ad_card.dart';

class AdsPage extends StatelessWidget {
  const AdsPage({super.key});

  static void push(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdsBloc>()..add(const FetchAdsEvent()),
      child: const _AdsView(),
    );
  }
}

class _AdsView extends StatelessWidget {
  const _AdsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ads',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<AdsBloc, AdsState>(
        builder: (context, state) {
          if (state is AdsLoading) {
            return Center(child: AppLoading.circular());
          }
          if (state is AdsError) {
            return Center(
              child: Text(state.message, style: const TextStyle(color: AppColors.inkSub)),
            );
          }
          if (state is AdsLoaded && state.ads.isEmpty) {
            return const Center(
              child: Text('No ads available', style: TextStyle(color: AppColors.inkSub)),
            );
          }
          if (state is AdsLoaded) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.ads.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (_, i) => AdCard(ad: state.ads[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
