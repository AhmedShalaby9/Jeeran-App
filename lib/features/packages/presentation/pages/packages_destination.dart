import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../plans/presentation/pages/plans_page.dart';
import '../../../subscription/presentation/pages/subscription_details_page.dart';

class PackagesDestination extends StatelessWidget {
  const PackagesDestination({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = state is AuthMeLoaded ? state.user : null;
        final hasSubscription = user?.subscriptionId != null;

        if (hasSubscription) {
          return const SubscriptionDetailsPage();
        }

        return const PlansPage();
      },
    );
  }
}
