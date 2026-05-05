import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
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
      create: (_) => sl<SubscriptionBloc>()..add(const FetchMySubscriptionEvent()),
      child: const _SubscriptionDetailsView(),
    );
  }
}

class _SubscriptionDetailsView extends StatelessWidget {
  const _SubscriptionDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
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
    );
  }

  Future<void> _openUpgradePage(BuildContext context, int currentPlanId) async {
    final bloc = context.read<SubscriptionBloc>();
    final upgraded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PlansPage(currentPlanId: currentPlanId),
      ),
    );
    if (upgraded == true) {
      bloc.add(const FetchMySubscriptionEvent());
    }
  }

  Widget _buildContent(BuildContext context, UserSubscription subscription) {
    final plan = subscription.package;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(
          child: SubscriptionHeroCard(subscription: subscription),
        ),
        SliverToBoxAdapter(child: _buildQuickActions(context, subscription)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(
            children: [
              SubscriptionSection(
                title: 'subscription.plan'.tr(),
                children: [
                  DetailRow(label: 'subscription.tier'.tr(), value: plan.name),
                  DetailRow(label: 'subscription.monthly_listings'.tr(), value: '${plan.availableListings}', chevron: false),
                  DetailRow(label: 'subscription.next_renewal'.tr(), value: _formatDate(subscription.endDate), chevron: false, last: true),
                ],
              ),
              SubscriptionSection(
                title: 'subscription.add_ons'.tr(),
                action: 'subscription.add'.tr(),
                children: [
                  DetailRow(label: 'subscription.payg_wallet'.tr(), value: '15 ${'currency'.tr()}', valueColor: AppColors.primary),
                  DetailRow(label: 'subscription.featured_placements'.tr(), value: '2 remaining', last: true),
                ],
              ),
              SubscriptionSection(
                title: 'subscription.payment_method'.tr(),
                action: 'subscription.change'.tr(),
                children: const [FawryRow()],
              ),
              SubscriptionSection(
                title: 'subscription.billing_history'.tr(),
                action: 'subscription.see_all'.tr(),
                children: [
                  BillingRow(date: 'Apr 18, 2026', amount: '49.00 ${'currency'.tr()}'),
                  BillingRow(date: 'Mar 18, 2026', amount: '49.00 ${'currency'.tr()}'),
                  BillingRow(date: 'Feb 18, 2026', amount: '19.00 ${'currency'.tr()}', last: true),
                ],
              ),
              SubscriptionSection(
                title: 'subscription.manage'.tr(),
                children: [
                  DetailRow(label: 'subscription.switch_plan'.tr(), value: ''),
                  DetailRow(label: 'subscription.pause_renewal'.tr(), value: ''),
                  ManageRow(label: 'subscription.cancel'.tr(), danger: true),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                child: Text(
                  'subscription.cancel_note'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.inkMute, height: 1.5),
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
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
          const SizedBox(width: 10),
          QuickAction(
            label: 'subscription.invoices'.tr(),
            iconBg: AppColors.tagNeutralBg,
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.inkSub,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
