import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;

  const ProfileHeader({super.key, required this.step, this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: step == 1 ? 0.4 : 1.0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.navButtonBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        step == 1
                            ? 'auth.create_profile'.tr()
                            : 'auth.more_about_you'.tr(),
                        key: ValueKey(step),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Step $step of 2 · ${step == 1 ? 'auth.step_required'.tr() : 'auth.step_optional'.tr()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: step / 2,
              minHeight: 3,
              backgroundColor: const Color(0xFFEEF0F4),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
