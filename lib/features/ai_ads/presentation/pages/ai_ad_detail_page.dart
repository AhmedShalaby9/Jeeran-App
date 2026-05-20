import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/ai_ad.dart';
import '../bloc/ai_ad_detail_bloc.dart';
import '../bloc/ai_ad_detail_event.dart';
import '../bloc/ai_ad_detail_state.dart';

class AiAdDetailPage extends StatelessWidget {
  final int adId;
  const AiAdDetailPage({super.key, required this.adId});

  static Future<void> push(BuildContext context, int adId) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AiAdDetailPage(adId: adId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AiAdDetailBloc>()..add(LoadAiAdDetail(adId)),
      child: _AiAdDetailView(adId: adId),
    );
  }
}

class _AiAdDetailView extends StatefulWidget {
  final int adId;
  const _AiAdDetailView({required this.adId});

  @override
  State<_AiAdDetailView> createState() => _AiAdDetailViewState();
}

class _AiAdDetailViewState extends State<_AiAdDetailView> {
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      context.read<AiAdDetailBloc>().add(RefreshAiAdDetail(widget.adId));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _showCreateTrialSheet(BuildContext context, AiAd ad) {
    final captionCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Re-generate Ad (Free Trial)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Describe how you want the ad refined. The same images will be used.',
                style: TextStyle(fontSize: 13, color: AppColors.inkSub),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'e.g. Make it more professional, highlight the price...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final caption = captionCtrl.text.trim();
                    if (caption.isEmpty) return;
                    Navigator.pop(sheetCtx);
                    context.read<AiAdDetailBloc>().add(
                          CreateAiAdTrial(
                            parentId: ad.id,
                            caption: caption,
                          ),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Re-generation',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('AI Ad Detail')),
      body: BlocConsumer<AiAdDetailBloc, AiAdDetailState>(
        listener: (context, state) {
          if (state is AiAdDetailLoaded) {
            if (state.ad.isPending) {
              _startPolling();
            } else if (state.ad.isAwaitingPayment) {
              _stopPolling();
            } else {
              _stopPolling();
            }
            if (state.trialError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.trialError!),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          }
          if (state is AiAdTrialCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trial created — generating now...'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is AiAdDetailError) {
            _stopPolling();
          }
        },
        builder: (context, state) {
          if (state is AiAdDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is AiAdDetailError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<AiAdDetailBloc>()
                        .add(LoadAiAdDetail(widget.adId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loaded = state is AiAdDetailLoaded ? state : null;
          if (loaded == null) return const SizedBox.shrink();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => context
                .read<AiAdDetailBloc>()
                .add(RefreshAiAdDetail(widget.adId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _AdResultCard(ad: loaded.ad),
                if (loaded.ad.isAwaitingPayment) ...[
                  const SizedBox(height: 16),
                  _PaymentPendingBanner(
                    adId: loaded.ad.id,
                    isChecking: loaded.isCheckingPayment,
                  ),
                ],
                const SizedBox(height: 24),
                _TrialsSection(
                  ad: loaded.ad,
                  trials: loaded.trials,
                  isCreating: loaded.isCreatingTrial,
                  onCreateTrial: () => _showCreateTrialSheet(context, loaded.ad),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Payment Pending Banner ───────────────────────────────────────────────────

class _PaymentPendingBanner extends StatelessWidget {
  final int adId;
  final bool isChecking;
  const _PaymentPendingBanner({required this.adId, required this.isChecking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Awaiting Payment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'After completing payment, tap the button below to activate your ad.',
            style: TextStyle(fontSize: 13, color: AppColors.inkSub),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isChecking
                  ? null
                  : () => context
                      .read<AiAdDetailBloc>()
                      .add(CheckAiAdPayment(adId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "I've Completed Payment",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ad Result Card ───────────────────────────────────────────────────────────

class _AdResultCard extends StatelessWidget {
  final AiAd ad;
  const _AdResultCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(status: ad.status),
                    const Spacer(),
                    if (ad.isPending) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Generating...',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.inkSub),
                      ),
                    ],
                  ],
                ),
                if (ad.isDone && ad.resultUrl != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(ad.resultUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Caption',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSub,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ad.caption,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.onBackground),
                ),
                if (ad.isFailed && ad.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ad.errorMessage!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.danger),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final url = ad.resultUrl ?? (ad.sourceImages.isNotEmpty ? ad.sourceImages.first : null);
    if (url == null) return _imagePlaceholder();
    return Image.network(
      url,
      width: double.infinity,
      height: ad.resultUrl != null ? 360 : 220,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      color: AppColors.primary.withValues(alpha: 0.06),
      child: const Icon(Icons.auto_awesome_outlined,
          size: 60, color: AppColors.primary),
    );
  }
}

// ── Trials Section ───────────────────────────────────────────────────────────

class _TrialsSection extends StatelessWidget {
  final AiAd ad;
  final List<AiAd> trials;
  final bool isCreating;
  final VoidCallback onCreateTrial;

  const _TrialsSection({
    required this.ad,
    required this.trials,
    required this.isCreating,
    required this.onCreateTrial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Re-generation Trials',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            if (ad.isDone)
              isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: onCreateTrial,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Trial'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary),
                    ),
          ],
        ),
        if (!ad.isDone)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              ad.isPending
                  ? 'Trials become available once the original ad finishes generating.'
                  : 'Trials are not available for failed ads.',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.inkSub),
            ),
          )
        else if (trials.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No trials yet. Tap "New Trial" to refine this ad for free.',
              style: TextStyle(fontSize: 13, color: AppColors.inkSub),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.only(top: 12),
            itemCount: trials.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TrialCard(trial: trials[i]),
          ),
      ],
    );
  }
}

class _TrialCard extends StatelessWidget {
  final AiAd trial;
  const _TrialCard({required this.trial});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: _buildImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Trial #${trial.trialNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: trial.status, small: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  trial.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSub),
                ),
                if (trial.resultUrl != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(trial.resultUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final url = trial.resultUrl ??
        (trial.sourceImages.isNotEmpty ? trial.sourceImages.first : null);
    if (url == null) return _placeholder();
    return Image.network(
      url,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        height: 200,
        color: AppColors.primary.withValues(alpha: 0.06),
        child: const Icon(Icons.auto_awesome_outlined,
            size: 40, color: AppColors.primary),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool small;
  const _StatusBadge({required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'done' => ('Done', Colors.green),
      'failed' => ('Failed', AppColors.danger),
      'processing' => ('Processing', Colors.orange),
      _ => ('Pending', AppColors.grey),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
