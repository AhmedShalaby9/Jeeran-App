import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../bloc/seller_request_bloc.dart';
import '../bloc/seller_request_event.dart';
import '../bloc/seller_request_state.dart';

/// Shows a "Join as seller" tile only when the stored user type is not seller.
/// Visibility is driven by [AppStorage.isSeller] — no AuthBloc dependency.
class SellerRequestTile extends StatelessWidget {
  const SellerRequestTile({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppStorage.isSeller) return const SizedBox.shrink();

    return BlocBuilder<SellerRequestBloc, SellerRequestState>(
      builder: (context, state) {
        final isLoading = state is SellerRequestLoading;

        return Container(
          margin: const EdgeInsets.only(bottom: 9, top: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.09),
                AppColors.secondary.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          child: ListTile(
            onTap: isLoading
                ? null
                : () => context.read<SellerRequestBloc>().add(
                    const SubmitSellerRequestEvent(),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              'more.join_as_seller_title'.tr(),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.onBackground,
              ),
            ),
            trailing: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
          ),
        );
      },
    );
  }
}
