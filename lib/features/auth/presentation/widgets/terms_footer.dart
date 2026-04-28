import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';

class TermsFooter extends StatelessWidget {
  const TermsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.of(context).padding.bottom),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: AppColors.inkMute, height: 1.5),
          children: [
            TextSpan(text: 'auth.terms_prefix'.tr()),
            TextSpan(
              text: 'auth.terms_of_service'.tr(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: 'auth.terms_connector'.tr()),
            TextSpan(
              text: 'auth.privacy_policy'.tr(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
