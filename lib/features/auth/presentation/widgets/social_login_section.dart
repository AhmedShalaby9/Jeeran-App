import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import 'auth_social_button.dart';

class SocialLoginSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  const SocialLoginSection({
    super.key,
    required this.isLoading,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.hairline, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'auth.or_sign_in_with'.tr(),
                style: const TextStyle(fontSize: 13, color: AppColors.inkMute),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.hairline, thickness: 1)),
          ],
        ),
        const SizedBox(height: 16),
        AuthSocialButton(
          label: 'auth.google'.tr(),
          icon: const Icon(FontAwesomeIcons.google, size: 18, color: AppColors.ink),
          isLoading: isLoading,
          onTap: onGoogleTap,
        ),
        if (Platform.isIOS) ...[
          const SizedBox(height: 12),
          AuthSocialButton(
            label: 'auth.apple'.tr(),
            icon: const Icon(FontAwesomeIcons.apple, size: 20, color: AppColors.ink),
            isLoading: isLoading,
            onTap: onAppleTap,
          ),
        ],
      ],
    );
  }
}
