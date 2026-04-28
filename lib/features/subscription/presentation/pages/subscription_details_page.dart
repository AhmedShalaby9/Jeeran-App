import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';


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
          SliverToBoxAdapter(child: _buildHeroCard()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.list(
              children: [
                _Section(
                  title: 'PLAN',
                  children: [
                    _DetailRow(label: 'Tier', value: 'Growth'),
                    _DetailRow(label: 'Monthly listings', value: '20', chevron: false),
                    _DetailRow(label: 'Next renewal', value: 'May 18, 2026', chevron: false, last: true),
                  ],
                ),
                _Section(
                  title: 'ADD-ONS',
                  action: 'Add',
                  children: [
                    _DetailRow(label: 'Pay-as-you-go wallet', value: '15 JOD', valueColor: AppColors.primary),
                    _DetailRow(label: 'Featured placements', value: '2 remaining', last: true),
                  ],
                ),
                _Section(
                  title: 'PAYMENT METHOD',
                  action: 'Change',
                  children: [_FawryRow()],
                ),
                _Section(
                  title: 'BILLING HISTORY',
                  action: 'See all',
                  children: [
                    _BillingRow(date: 'Apr 18, 2026', amount: '49.00 JOD'),
                    _BillingRow(date: 'Mar 18, 2026', amount: '49.00 JOD'),
                    _BillingRow(date: 'Feb 18, 2026', amount: '19.00 JOD', last: true),
                  ],
                ),
                _Section(
                  title: 'MANAGE',
                  children: [
                    _DetailRow(label: 'Switch plan', value: ''),
                    _DetailRow(label: 'Pause renewal', value: ''),
                    _ManageRow(label: 'Cancel subscription', danger: true),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 24),
                  child: Text(
                    'Cancel anytime. Already-published listings stay visible until your cycle ends.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.inkMute, height: 1.5),
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
                width: 36, height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2F4F7)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
              ),
            ),
            const Expanded(
              child: Text(
                'Subscription',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final pct = _used / _total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2A4A), Color(0xFF143763)],
            stops: [0, 1],
          ),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              top: -60, right: -40,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.gold.withValues(alpha: 0.15), const Color(0x00B8893D)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ActiveTag(),
                      const SizedBox(width: 8),
                      Text('Renews May 18, 2026', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Growth plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text('49', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.2, height: 1)),
                      const SizedBox(width: 6),
                      Text('JOD / month', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Listings used this cycle', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                      Text('$_used of $_total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_total - _used} remaining آ· resets in 12 days',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
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
          _QuickAction(
            label: 'New listing',
            iconBg: AppColors.primary.withValues(alpha: 0.08),
            icon: Icons.add_rounded,
            iconColor: AppColors.primary,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _QuickAction(
            label: 'Upgrade',
            iconBg: AppColors.goldSoft,
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.gold,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _QuickAction(
            label: 'Invoices',
            iconBg: const Color(0xFFEEF0F4),
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.inkSub,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Section wrapper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Section extends StatelessWidget {
  final String title;
  final String? action;
  final List<Widget> children;
  const _Section({required this.title, required this.children, this.action});

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
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.inkMute, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                if (action != null)
                  GestureDetector(
                    onTap: () {},
                    child: Text(action!, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
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

// â”€â”€ Row types â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool chevron, last;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.chevron = true, this.last = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.inkSub))),
          if (value.isNotEmpty)
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.ink)),
          if (chevron) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMute),
          ],
        ],
      ),
    );
  }
}

class _ManageRow extends StatelessWidget {
  final String label;
  final bool danger;
  const _ManageRow({required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: danger ? AppColors.danger : AppColors.ink, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMute),
        ],
      ),
    );
  }
}

class _BillingRow extends StatelessWidget {
  final String date, amount;
  final bool last;
  const _BillingRow({required this.date, required this.amount, this.last = false});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Growth â€” monthly', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(fontSize: 12, color: AppColors.inkSub)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 2),
              const Text('Paid', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMute),
        ],
      ),
    );
  }
}

class _FawryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46, height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF143763)]),
            ),
            child: const Center(
              child: Text('FAWRY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fawry Pay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                Text('+962 79 â€¢â€¢ â€¢â€¢ 342', style: TextStyle(fontSize: 12, color: AppColors.inkSub)),
              ],
            ),
          ),
          _DefaultTag(),
        ],
      ),
    );
  }
}

// â”€â”€ Small components â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActiveTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF5D89A), letterSpacing: 0.2)),
    );
  }
}

class _DefaultTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text('Default', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final Color iconBg, iconColor;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.iconBg, required this.icon, required this.iconColor, required this.onTap});

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
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

