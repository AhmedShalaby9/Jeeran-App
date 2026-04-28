 import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/plan.dart';
import '../bloc/plans_bloc.dart';
import '../bloc/plans_event.dart';
import '../bloc/plans_state.dart';
import '../widgets/billing_toggle.dart';
import '../widgets/nav_icon_button.dart';
import '../widgets/payg_section.dart';
import '../widgets/plan_card.dart';
import '../widgets/plans_sticky_button.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  String _billing = 'monthly';
  int? _selectedPlanId;

  Plan? _selectDefault(List<Plan> plans) {
    if (plans.isEmpty) return null;
    final growth = plans.firstWhere(
      (p) => p.name.toLowerCase() == 'growth',
      orElse: () => plans.first,
    );
    return growth;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PlansBloc>()..add(const FetchPlansEvent()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<PlansBloc, PlansState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildTopBar()),
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(
                        child: BillingToggle(
                          selected: _billing,
                          onChanged: (v) => setState(() => _billing = v),
                        ),
                      ),
                      if (_billing == 'monthly') ...[
                        if (state is PlansLoading)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        else if (state is PlansError)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.inkSub,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (state is PlansLoaded)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList.builder(
                              itemCount: state.plans.length,
                              itemBuilder: (_, i) {
                                final plan = state.plans[i];
                                final defaultPlan = _selectDefault(state.plans);
                                final selectedId = _selectedPlanId ?? defaultPlan?.id;
                                final isSelected = selectedId == plan.id;
                                final isRecommended = plan.name.toLowerCase() == 'growth';
                                return PlanCard(
                                  plan: plan,
                                  selected: isSelected,
                                  recommended: isRecommended,
                                  onTap: () => setState(
                                    () => _selectedPlanId = plan.id,
                                  ),
                                );
                              },
                            ),
                          ),
                      ] else
                        const SliverToBoxAdapter(child: PaygSection()),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
                if (state is PlansLoaded && _billing == 'monthly')
                  PlansStickyButton(
                    billing: _billing,
                    price: _activePrice(state.plans),
                  )
                else if (_billing == 'payg')
                  PlansStickyButton(
                    billing: _billing,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _activePrice(List<Plan> plans) {
    final defaultPlan = _selectDefault(plans);
    final active = plans.firstWhere(
      (p) => p.id == (_selectedPlanId ?? defaultPlan?.id),
      orElse: () => plans.first,
    );
    return active.price;
  }

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            NavIconButton(onTap: () => Navigator.maybePop(context)),
            GestureDetector(
              onTap: () {},
              child: Text(
                'plans.restore'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
          Text(
            'plans.title'.tr(),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'plans.subtitle'.tr(),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.inkSub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
