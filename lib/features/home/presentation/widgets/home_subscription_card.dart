import 'package:flutter/material.dart';
import '../../../plans/presentation/widgets/upgrade_promo_card.dart';
import '../../../subscription/presentation/widgets/subscription_status_card.dart';

enum HomeSubscriptionState { unsubscribed, active, lowQuota }

class HomeSubscriptionCard extends StatelessWidget {
  final HomeSubscriptionState state;

  const HomeSubscriptionCard({super.key, required this.state});

  factory HomeSubscriptionCard.unsubscribed() =>
      const HomeSubscriptionCard(state: HomeSubscriptionState.unsubscribed);

  factory HomeSubscriptionCard.active() =>
      const HomeSubscriptionCard(state: HomeSubscriptionState.active);

  factory HomeSubscriptionCard.lowQuota() =>
      const HomeSubscriptionCard(state: HomeSubscriptionState.lowQuota);

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      HomeSubscriptionState.unsubscribed => const UpgradePromoCard(),
      HomeSubscriptionState.active => const SubscriptionStatusCard(
        status: SubscriptionStatus.active,
      ),
      HomeSubscriptionState.lowQuota => const SubscriptionStatusCard(
        status: SubscriptionStatus.lowQuota,
      ),
    };
  }
}
