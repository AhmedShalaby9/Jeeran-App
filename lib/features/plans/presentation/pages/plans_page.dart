import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/plan.dart';
import '../bloc/plans_bloc.dart';
import '../bloc/plans_event.dart';
import '../bloc/plans_state.dart';
import '../widgets/nav_icon_button.dart';
import '../widgets/plan_card.dart';
import '../widgets/plans_sticky_button.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../subscription/presentation/bloc/subscription_state.dart';
import '../../../subscription/presentation/widgets/subscription_success_sheet.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class PlansPage extends StatefulWidget {
  /// When provided, pre-selects this plan and uses the upgrade endpoint.
  final int? currentPlanId;

  const PlansPage({super.key, this.currentPlanId});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  int? _selectedPlanId;

  bool get _isUpgrade => widget.currentPlanId != null;

  Plan? _selectDefault(List<Plan> plans) {
    if (plans.isEmpty) return null;
    if (_isUpgrade) {
      return plans.firstWhere(
        (p) => p.id == widget.currentPlanId,
        orElse: () => plans.first,
      );
    }
    return plans.firstWhere(
      (p) => p.name.toLowerCase() == 'growth',
      orElse: () => plans.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PlansBloc>()..add(const FetchPlansEvent())),
        BlocProvider(create: (_) => sl<SubscriptionBloc>()),
      ],
      child: BlocListener<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) async {
          if (state is SubscriptionSuccess) {
            context.read<AuthBloc>().add(const AuthGetMeEvent());
            await SubscriptionSuccessSheet.show(context);
          } else if (state is UpgradeSubscriptionSuccess) {
            AppSnackbar.show(
              context,
              message: 'subscription.upgrade_success'.tr(),
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
            );
            Navigator.pop(context, true);
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
          body: BlocBuilder<PlansBloc, PlansState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildTopBar()),
                        SliverToBoxAdapter(child: _buildHeader()),
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
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                  if (state is PlansLoaded)
                    BlocBuilder<SubscriptionBloc, SubscriptionState>(
                      builder: (context, subState) => PlansStickyButton(
                        price: _activePrice(state.plans),
                        isUpgrade: _isUpgrade,
                        onPressed: subState is SubscriptionLoading
                            ? null
                            : () {
                                final planId = _selectedPlanId ??
                                    _selectDefault(state.plans)?.id;
                                if (planId == null) return;
                                if (_isUpgrade) {
                                  context.read<SubscriptionBloc>().add(
                                        UpgradeSubscriptionEvent(packageId: planId),
                                      );
                                } else {
                                  context.read<SubscriptionBloc>().add(
                                        CreateSubscriptionEvent(packageId: planId),
                                      );
                                }
                              },
                      ),
                    ),
                ],
              );
            },
          ),
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
