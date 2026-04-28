import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import 'auth_primary_button.dart';

class ProfileCTABar extends StatelessWidget {
  final int step;
  final bool step1Valid;
  final bool step2Valid;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  const ProfileCTABar({
    super.key,
    required this.step,
    required this.step1Valid,
    this.step2Valid = false,
    required this.onContinue,
    required this.onSkip,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: step == 1
          ? AuthPrimaryButton(
              label: 'auth.continue'.tr(),
              enabled: step1Valid,
              onTap: onContinue,
            )
          : Row(
              children: [
                GestureDetector(
                  onTap: onSkip,
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.hairline, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'auth.skip'.tr(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSub),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AuthPrimaryButton(
                    label: 'auth.complete_setup'.tr(),
                    enabled: step2Valid,
                    onTap: onComplete,
                  ),
                ),
              ],
            ),
    );
  }
}
