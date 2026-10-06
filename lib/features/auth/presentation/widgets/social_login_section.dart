import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/widgets/jv2.dart';

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
    final google = JV2GhostButton(
      onPressed: isLoading ? null : onGoogleTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(
            FontAwesomeIcons.google,
            size: 17,
            color: Color(0xFF4285F4),
          ),
          const SizedBox(width: 10),
          Text('auth.google'.tr()),
        ],
      ),
    );
    final apple = JV2GhostButton(
      onPressed: isLoading ? null : onAppleTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.apple, size: 20, color: JV2.ink),
          const SizedBox(width: 10),
          Text('auth.apple'.tr()),
        ],
      ),
    );

    return Column(
      children: [
        const SizedBox(height: 30),
        Row(
          children: [
            const Expanded(child: Divider(color: JV2.line, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'auth.or'.tr().toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                  color: JV2.inkMute,
                ),
              ),
            ),
            const Expanded(child: Divider(color: JV2.line, height: 1)),
          ],
        ),
        const SizedBox(height: 30),
        if (Platform.isIOS)
          Row(
            children: [
              Expanded(child: google),
              const SizedBox(width: 12),
              Expanded(child: apple),
            ],
          )
        else
          SizedBox(width: double.infinity, child: google),
      ],
    );
  }
}
