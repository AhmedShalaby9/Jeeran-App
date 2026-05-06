import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../properties/presentation/pages/add_property_page.dart';
import '../../domain/entities/user_subscription.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';
import '../widgets/subscription_hero_card.dart';
import '../widgets/subscription_widgets.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SubscriptionBloc>()
        ..add(const FetchMySubscriptionEvent())
        ..add(const FetchSubscriptionHistoryEvent()),
      child: const _SubscriptionDetailsView(),
    );
  }
}

class _SubscriptionDetailsView extends StatelessWidget {
  const _SubscriptionDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state is CancelSubscriptionSuccess) {
          HomePage.reset();
          context.read<AuthBloc>().add(const AuthGetMeEvent());
          AppSnackbar.show(
            context,
            message: 'subscription.cancel_success'.tr(),
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
          );
          MainPage.switchTab(0);
        } else if (state is SubscriptionError) {
          AppSnackbar.show(
            context,
            message: state.message,
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.danger,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          buildWhen: (_, curr) =>
              curr is MySubscriptionLoading ||
              curr is MySubscriptionLoaded ||
              curr is MySubscriptionError,
          builder: (context, state) {
            if (state is MySubscriptionLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is MySubscriptionError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.inkMute),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkSub),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.read<SubscriptionBloc>().add(const FetchMySubscriptionEvent()),
                        child: Text('subscription.retry'.tr()),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is MySubscriptionLoaded) {
              return _buildContent(context, state.subscription);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<void> _openUpgradePage(BuildContext context, int currentPlanId) async {
    final bloc = context.read<SubscriptionBloc>();
    final upgraded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PlansPage(currentPlanId: currentPlanId)),
    );
    if (upgraded == true) {
      bloc
        ..add(const FetchMySubscriptionEvent())
        ..add(const FetchSubscriptionHistoryEvent());
    }
  }

  Future<void> _showCancelSheet(BuildContext context) async {
    final bloc = context.read<SubscriptionBloc>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CancelConfirmSheet(),
    );
    if (confirmed == true) {
      bloc.add(const CancelSubscriptionEvent());
    }
  }

  Widget _buildContent(BuildContext context, UserSubscription subscription) {
    final plan = subscription.package;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: SubscriptionHeroCard(subscription: subscription)),
        SliverToBoxAdapter(child: _buildQuickActions(context, subscription)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(
            children: [
              // ── Plan details ────────────────────────────────────────
              SubscriptionSection(
                title: 'subscription.plan'.tr(),
                children: [
                  DetailRow(label: 'subscription.tier'.tr(), value: plan.name),
                  DetailRow(
                    label: 'subscription.monthly_listings'.tr(),
                    value: '${subscription.availableListings}',
                    chevron: false,
                  ),
                  DetailRow(
                    label: 'subscription.next_renewal'.tr(),
                    value: _formatDate(subscription.endDate),
                    chevron: false,
                    last: true,
                  ),
                ],
              ),

              // ── Billing history (real data) ─────────────────────────
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                buildWhen: (_, curr) =>
                    curr is SubscriptionHistoryLoading ||
                    curr is SubscriptionHistoryLoaded ||
                    curr is SubscriptionHistoryError,
                builder: (context, state) {
                  if (state is SubscriptionHistoryLoading) {
                    return SubscriptionSection(
                      title: 'subscription.billing_history'.tr(),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  if (state is SubscriptionHistoryLoaded && state.history.isNotEmpty) {
                    return SubscriptionSection(
                      title: 'subscription.billing_history'.tr(),
                      children: state.history.asMap().entries.map((e) {
                        return BillingRow(
                          subscription: e.value,
                          last: e.key == state.history.length - 1,
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // ── Manage ──────────────────────────────────────────────
              SubscriptionSection(
                title: 'subscription.manage'.tr(),
                children: [
                  ManageRow(
                    label: 'subscription.upgrade'.tr(),
                    onTap: () => _openUpgradePage(context, subscription.packageId),
                  ),
                  BlocBuilder<SubscriptionBloc, SubscriptionState>(
                    builder: (context, state) => ManageRow(
                      label: state is SubscriptionLoading
                          ? 'subscription.cancelling'.tr()
                          : 'subscription.cancel'.tr(),
                      danger: true,
                      last: true,
                      onTap: state is SubscriptionLoading
                          ? null
                          : () => _showCancelSheet(context),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                child: Text(
                  'subscription.cancel_note'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkMute,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navButtonBg,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'subscription.title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserSubscription subscription) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Row(
        children: [
          QuickAction(
            label: 'subscription.new_listing'.tr(),
            iconBg: AppColors.primary.withValues(alpha: 0.08),
            icon: Icons.add_rounded,
            iconColor: AppColors.primary,
            onTap: () => AddPropertyPage.push(context),
          ),
          const SizedBox(width: 10),
          QuickAction(
            label: 'subscription.upgrade'.tr(),
            iconBg: AppColors.goldSoft,
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.gold,
            onTap: () => _openUpgradePage(context, subscription.packageId),
          ),
        ],
      ),
    );
  }
}

// ── Cancel confirmation sheet ─────────────────────────────────────────────────

class _CancelConfirmSheet extends StatelessWidget {
  const _CancelConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined, size: 32, color: AppColors.danger),
          ),
          const SizedBox(height: 20),
          Text(
            'subscription.cancel_confirm_title'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'subscription.cancel_confirm_body'.tr(),
            style: const TextStyle(fontSize: 14, color: AppColors.inkSub, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'subscription.keep_plan'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'subscription.confirm_cancel'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
