import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/user_subscription.dart';

class SubscriptionSection extends StatelessWidget {
  final String title;
  final String? action;
  final List<Widget> children;

  const SubscriptionSection({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkMute,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                if (action != null)
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      action!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairline),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool chevron;
  final bool last;
  final Color? valueColor;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.chevron = true,
    this.last = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.inkSub),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.ink,
              ),
            ),
          if (chevron) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMute),
          ],
        ],
      ),
    );
  }
}

class ManageRow extends StatelessWidget {
  final String label;
  final bool danger;
  final bool last;
  final VoidCallback? onTap;

  const ManageRow({super.key, required this.label, this.danger = false, this.last = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: danger ? AppColors.danger : AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMute),
        ],
      ),
      ),
    );
  }
}

class BillingRow extends StatelessWidget {
  final UserSubscription subscription;
  final bool last;

  const BillingRow({super.key, required this.subscription, this.last = false});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(subscription.startDate);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = dt != null ? '${months[dt.month - 1]} ${dt.day}, ${dt.year}' : subscription.startDate;
    final status = subscription.status;
    final (statusLabel, statusColor) = switch (status) {
      'active'   => ('Active', AppColors.success),
      'upgraded' => ('Upgraded', AppColors.primary),
      'cancelled'=> ('Cancelled', AppColors.danger),
      _          => (status, AppColors.inkMute),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subscription.package.name} — monthly',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.inkSub)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${subscription.package.price} EGP',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FawryRow extends StatelessWidget {
  const FawryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.heroGradientEnd],
              ),
            ),
            child: const Center(
              child: Text(
                'FAWRY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fawry Pay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                Text(
                  '+962 79 •• •• 342',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSub),
                ),
              ],
            ),
          ),
          const DefaultTag(),
        ],
      ),
    );
  }
}

class ActiveTag extends StatelessWidget {
  const ActiveTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Active',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.goldLight,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class DefaultTag extends StatelessWidget {
  const DefaultTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Default',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final String label;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.label,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
