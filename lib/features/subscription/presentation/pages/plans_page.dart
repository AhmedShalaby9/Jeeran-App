import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

const _kGold = Color(0xFFB8893D);
const _kGoldSoft = Color(0xFFF5ECDB);
const _kBg = Color(0xFFF5F6F8);
const _kInk = Color(0xFF0E1726);
const _kInkSub = Color(0xFF5B6474);
const _kInkMute = Color(0xFF8A93A3);
const _kHairline = Color(0x14081E3C);

class _Plan {
  final String id, name, tagline;
  final int price, ads;
  final List<String> features;
  final bool recommended;
  const _Plan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    required this.ads,
    required this.features,
    this.recommended = false,
  });
}

const _plans = [
  _Plan(
    id: 'starter',
    name: 'Starter',
    tagline: 'For new agents',
    price: 19,
    ads: 5,
    features: ['5 active listings / month', 'Basic analytics', 'Standard placement', 'Email support'],
  ),
  _Plan(
    id: 'growth',
    name: 'Growth',
    tagline: 'Most popular',
    price: 49,
    ads: 20,
    recommended: true,
    features: ['20 active listings / month', 'Detailed analytics', 'Boosted placement ×2', 'WhatsApp leads', 'Priority support'],
  ),
  _Plan(
    id: 'pro',
    name: 'Pro',
    tagline: 'Top-producing agents',
    price: 99,
    ads: 60,
    features: ['60 active listings / month', 'Advanced analytics', 'Featured placement ×5', 'Lead CRM', '24/7 support'],
  ),
];

const _paygPacks = [
  (ads: 1, price: 5, save: ''),
  (ads: 3, price: 13, save: '13%'),
  (ads: 10, price: 39, save: '22%'),
];

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  String _billing = 'monthly';
  String _selected = 'growth';
  int _paygPick = 1;

  _Plan get _activePlan => _plans.firstWhere((p) => p.id == _selected);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar()),
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildBillingToggle()),
                if (_billing == 'monthly')
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: _plans.length,
                      itemBuilder: (_, i) => _PlanCard(
                        plan: _plans[i],
                        selected: _selected == _plans[i].id,
                        onTap: () => setState(() => _selected = _plans[i].id),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(child: _buildPayg()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          _buildStickyButton(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavIconButton(onTap: () => Navigator.maybePop(context)),
            GestureDetector(
              onTap: () {},
              child: const Text('Restore', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unlock listing uploads',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: _kInk, letterSpacing: -0.5, height: 1.1),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick a plan to start posting properties on Jeeran. Upgrade, downgrade or cancel anytime.',
            style: TextStyle(fontSize: 15, color: _kInkSub, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kHairline),
        ),
        child: Row(
          children: [
            _BillingTab(label: 'Monthly plan',    value: 'monthly', selected: _billing, onTap: (v) => setState(() => _billing = v)),
            _BillingTab(label: 'Pay as you go',   value: 'payg',    selected: _billing, onTap: (v) => setState(() => _billing = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayg() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // No-commitment banner
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kHairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: _kGoldSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.auto_awesome_rounded, color: _kGold, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No commitment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kInk)),
                      Text('Buy ad credits, use within 6 months.', style: TextStyle(fontSize: 12, color: _kInkSub)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Pack options
          ..._paygPacks.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final on = _paygPick == i;
            return GestureDetector(
              onTap: () => setState(() => _paygPick = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: on ? AppColors.primary : _kHairline,
                    width: on ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: Text('${p.ads}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${p.ads} ${p.ads == 1 ? 'ad' : 'ads'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kInk)),
                              if (p.save.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                _Tag(label: 'save ${p.save}', tone: _TagTone.gold),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${(p.price / p.ads).toStringAsFixed(2)} JOD per ad', style: const TextStyle(fontSize: 12, color: _kInkSub)),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '${p.price} ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kInk),
                        children: const [
                          TextSpan(text: 'JOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kInkSub)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStickyButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kBg.withValues(alpha: 0), _kBg],
          stops: const [0, 0.4],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _billing == 'monthly'
                    ? 'Subscribe — ${_activePlan.price} JOD/mo'
                    : 'Top up wallet',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Billed monthly via Fawry or wallet. Cancel anytime from settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _kInkMute, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : _kHairline,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4))]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (plan.recommended)
              Positioned(
                top: -26, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Recommended', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kInk)),
                        const SizedBox(height: 2),
                        Text(plan.tagline, style: const TextStyle(fontSize: 13, color: _kInkSub)),
                      ],
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: selected ? AppColors.primary : const Color(0xFFD5DAE2),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${plan.price}',
                      style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800,
                        color: AppColors.primary, letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('JOD / mo', style: TextStyle(fontSize: 14, color: _kInkSub, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${plan.ads} ads included', style: const TextStyle(fontSize: 13, color: _kInkSub)),
                  ],
                ),
                const SizedBox(height: 12),
                ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
                        ),
                        child: Icon(Icons.check_rounded, size: 9, color: selected ? Colors.white : AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(fontSize: 13, color: _kInk)),
                    ],
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────

class _BillingTab extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _BillingTab({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: double.infinity,
          decoration: BoxDecoration(
            color: on ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: on ? Colors.white : _kInkSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TagTone { gold, primary, success, neutral }

class _Tag extends StatelessWidget {
  final String label;
  final _TagTone tone;
  const _Tag({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _TagTone.gold    => (const Color(0xFFF5ECDB), const Color(0xFF7F5C1F)),
      _TagTone.primary => (const Color(0xFFEAF0F7), AppColors.primary),
      _TagTone.success => (const Color(0xFFE3F3EC), const Color(0xFF1E6E4D)),
      _TagTone.neutral => (const Color(0xFFEEF0F4), _kInkSub),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.2)),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NavIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2F4F7)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _kInk),
      ),
    );
  }
}
