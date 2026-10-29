import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/widgets/jv2.dart';

/// Full-width "Continue with Apple / Google" buttons (Jeeran v2 login).
/// Apple only shows on iOS, matching the platform's own sign-in conventions.
class SocialLoginSection extends StatelessWidget {
  final String? busyProvider; // 'apple' | 'google' | null
  final ValueChanged<String> onTap;

  const SocialLoginSection({
    super.key,
    required this.busyProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = busyProvider != null;
    return Column(
      children: [
        if (Platform.isIOS) ...[
          _SocialButton(
            dark: true,
            label: 'auth.continue_apple'.tr(),
            icon: const FaIcon(
              FontAwesomeIcons.apple,
              size: 20,
              color: Colors.white,
            ),
            busy: busyProvider == 'apple',
            onTap: disabled ? null : () => onTap('apple'),
          ),
          const SizedBox(height: 12),
        ],
        _SocialButton(
          dark: false,
          label: 'auth.continue_google'.tr(),
          icon: const FaIcon(
            FontAwesomeIcons.google,
            size: 17,
            color: Color(0xFF4285F4),
          ),
          busy: busyProvider == 'google',
          onTap: disabled ? null : () => onTap('google'),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final bool dark;
  final String label;
  final Widget icon;
  final bool busy;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.dark,
    required this.label,
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0E1726) : JV2.surface;
    final fg = dark ? Colors.white : JV2.ink;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: dark ? BorderSide.none : const BorderSide(color: JV2.line),
        ),
        shadowColor: dark ? const Color(0x380E1726) : Colors.transparent,
        elevation: dark ? 6 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: dark ? Colors.white : JV2.navy,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(width: 11),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
