import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import 'auth_primary_button.dart';
import 'auth_social_button.dart';

class LoginPhoneForm extends StatefulWidget {
  final bool isLoading;
  final ValueChanged<String> onContinue;

  const LoginPhoneForm({
    super.key,
    required this.isLoading,
    required this.onContinue,
  });

  @override
  State<LoginPhoneForm> createState() => _LoginPhoneFormState();
}

class _LoginPhoneFormState extends State<LoginPhoneForm> {
  final _phoneCtrl = TextEditingController();
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() {
      setState(() {
        _valid = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 10;
      });
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_valid || widget.isLoading) return;
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    widget.onContinue('+20$digits');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'auth.phone_number'.tr(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '+20',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                    ],
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.ink,
                      letterSpacing: 0.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'auth.phone_hint'.tr(),
                      hintStyle: const TextStyle(
                        color: AppColors.inkMute,
                        fontSize: 17,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.hairline,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.hairline,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'auth.phone_helper'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            label: 'auth.continue'.tr(),
            enabled: _valid && !widget.isLoading,
            onTap: _onContinue,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Divider(thickness: 1, color: AppColors.hairline),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'auth.or_sign_in_with'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMute,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(thickness: 1, color: AppColors.hairline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AuthSocialButton(
                  label: 'auth.apple'.tr(),
                  icon: Icons.apple_rounded,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthSocialButton(
                  label: 'auth.google'.tr(),
                  icon: Icons.g_mobiledata_rounded,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
