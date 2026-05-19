import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/ai_ad.dart';
import '../bloc/ai_ads_bloc.dart';
import '../bloc/ai_ads_event.dart';
import '../bloc/ai_ads_state.dart';
import 'ai_ad_detail_page.dart';
import 'ai_ad_generate_page.dart';

class AiAdsPage extends StatelessWidget {
  const AiAdsPage({super.key});

  static void push(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiAdsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AiAdsBloc>()..add(const LoadAiAds()),
      child: const _AiAdsView(),
    );
  }
}

class _AiAdsView extends StatelessWidget {
  const _AiAdsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My AI Ads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<AiAdsBloc>().add(const LoadAiAds()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await AiAdGeneratePage.push(context);
          if (context.mounted) {
            context.read<AiAdsBloc>().add(const LoadAiAds());
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          'Generate Ad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocBuilder<AiAdsBloc, AiAdsState>(
        builder: (context, state) {
          if (state is AiAdsLoading) return _buildShimmer();
          if (state is AiAdsError) return _buildError(context, state.message);

          final ads = state is AiAdsLoaded
              ? state.ads
              : state is AiAdsDeleting
                  ? state.ads
                  : <AiAd>[];

          if (ads.isEmpty) return _buildEmpty(context);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<AiAdsBloc>().add(const LoadAiAds()),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: ads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ad = ads[index];
                final isDeleting = state is AiAdsDeleting &&
                    state.deletingId == ad.id;
                return _AiAdCard(
                  ad: ad,
                  isDeleting: isDeleting,
                  onTap: () async {
                    await AiAdDetailPage.push(context, ad.id);
                    if (context.mounted) {
                      context.read<AiAdsBloc>().add(const LoadAiAds());
                    }
                  },
                  onDelete: () => _confirmDelete(context, ad),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AiAd ad) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text(
            'This will permanently delete the ad and all its trials.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<AiAdsBloc>().add(DeleteAiAd(ad.id));
      }
    });
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<AiAdsBloc>().add(const LoadAiAds()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 64, color: AppColors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No AI Ads yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate your first AI-powered ad using your property images.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAdCard extends StatelessWidget {
  final AiAd ad;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AiAdCard({
    required this.ad,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDeleting ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isDeleting ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ad.resultUrl != null
                    ? Image.network(
                        ad.resultUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : ad.sourceImages.isNotEmpty
                        ? Image.network(
                            ad.sourceImages.first,
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
                      ad.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(status: ad.status),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isDeleting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 20),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.auto_awesome_outlined,
          color: AppColors.primary, size: 28),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'done' => ('Done', Colors.green),
      'failed' => ('Failed', AppColors.danger),
      'processing' => ('Processing...', Colors.orange),
      _ => ('Pending', AppColors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
