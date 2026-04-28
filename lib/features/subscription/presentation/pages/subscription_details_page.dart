import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import '../widgets/subscription_hero_card.dart';
import '../widgets/subscription_widgets.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  const SubscriptionDetailsPage({super.key});

  static const _used = 6;
  static const _total = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          const SliverToBoxAdapter(
            child: SubscriptionHeroCard(used: _used, total: _total),
          ),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.list(
              children: [
                SubscriptionSection(
                  title: 'subscription.plan'.tr(),
                  children: [
                    DetailRow(label: 'subscription.tier'.tr(), value: 'Growth'),
                    DetailRow(label: 'subscription.monthly_listings'.tr(), value: '20', chevron: false),
                    DetailRow(label: 'subscription.next_renewal'.tr(), value: 'May 18, 2026', chevron: false, last: true),
                  ],
                ),
                SubscriptionSection(
                  title: 'subscription.add_ons'.tr(),
                  action: 'subscription.add'.tr(),
                  children: [
                    DetailRow(label: 'subscription.payg_wallet'.tr(), value: '15 JOD', valueColor: AppColors.primary),
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
                    BillingRow(date: 'Apr 18, 2026', amount: '49.00 JOD'),
                    BillingRow(date: 'Mar 18, 2026', amount: '49.00 JOD'),
                    BillingRow(date: 'Feb 18, 2026', amount: '19.00 JOD', last: true),
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
      ),
    );
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Row(
        children: [
          QuickAction(
            label: 'subscription.new_listing'.tr(),
            iconBg: AppColors.primary.withValues(alpha: 0.08),
            icon: Icons.add_rounded,
            iconColor: AppColors.primary,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          QuickAction(
            label: 'subscription.upgrade'.tr(),
            iconBg: AppColors.goldSoft,
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.gold,
            onTap: () {},
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
