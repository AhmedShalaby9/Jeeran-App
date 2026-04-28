import os

widgets_dir = 'lib/features/auth/presentation/widgets'
os.makedirs(widgets_dir, exist_ok=True)

files = {
    'auth_primary_button.dart': '''import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : const Color(0xFFD5DAE2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [const BoxShadow(color: Color(0x380B2A4A), blurRadius: 16, offset: Offset(0, 6))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.white : AppColors.inkMute,
            ),
          ),
        ),
      ),
    );
  }
}
''',
    'auth_social_button.dart': '''import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class AuthSocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const AuthSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
''',
    'dial_code.dart': '''class DialCode {
  final String flag, name, code;
  const DialCode(this.flag, this.name, this.code);
}

const dialCodes = [
  DialCode('🇯🇴', 'Jordan', '+962'),
  DialCode('🇪🇬', 'Egypt', '+20'),
  DialCode('🇸🇦', 'Saudi Arabia', '+966'),
  DialCode('🇦🇪', 'UAE', '+971'),
  DialCode('🇰🇼', 'Kuwait', '+965'),
  DialCode('🇧🇭', 'Bahrain', '+973'),
  DialCode('🇶🇦', 'Qatar', '+974'),
  DialCode('🇴🇲', 'Oman', '+968'),
  DialCode('🇮🇶', 'Iraq', '+964'),
  DialCode('🇱🇧', 'Lebanon', '+961'),
];
''',
    'dial_code_picker_sheet.dart': '''import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import 'dial_code.dart';

class DialCodePickerSheet extends StatelessWidget {
  final DialCode selected;
  final ValueChanged<DialCode> onSelect;

  const DialCodePickerSheet({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'auth.select_country_code'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(dialCodes.length, (i) {
            final d = dialCodes[i];
            final isSelected = d.code == selected.code;
            return InkWell(
              onTap: () {
                onSelect(d);
                Navigator.pop(context);
              },
              child: Container(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Text(d.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        d.name,
                        style: const TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(d.code, style: const TextStyle(fontSize: 13, color: AppColors.inkSub)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
''',
    'login_header.dart': '''import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28, topPad + 28, 28, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/icon/icon.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 52),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'auth.welcome_back'.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'auth.enter_phone'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSub, height: 1.4),
          ),
        ],
      ),
    );
  }
}
''',
    'login_phone_form.dart': '''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import 'auth_primary_button.dart';
import 'auth_social_button.dart';
import 'dial_code.dart';
import 'dial_code_picker_sheet.dart';

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
  DialCode _dial = dialCodes.first;
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() {
      final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
      setState(() => _valid = digits.length >= 8);
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _pickDialCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DialCodePickerSheet(
        selected: _dial,
        onSelect: (d) => setState(() => _dial = d),
      ),
    );
  }

  void _onContinue() {
    if (!_valid || widget.isLoading) return;
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    widget.onContinue('');
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
              GestureDetector(
                onTap: _pickDialCode,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_dial.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        _dial.code,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.inkMute),
                    ],
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
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]'))],
                    style: const TextStyle(fontSize: 17, color: AppColors.ink, letterSpacing: 0.3),
                    decoration: InputDecoration(
                      hintText: 'auth.phone_hint'.tr(),
                      hintStyle: const TextStyle(color: AppColors.inkMute, fontSize: 17),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.hairline, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.hairline, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
            style: const TextStyle(fontSize: 12, color: AppColors.inkMute, height: 1.4),
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
              const Expanded(child: Divider(thickness: 1, color: AppColors.hairline)),
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
              const Expanded(child: Divider(thickness: 1, color: AppColors.hairline)),
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
''',
    'terms_footer.dart': '''import 'package:flutter/material.dart';
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
''',
}

for name, content in files.items():
    path = os.path.join(widgets_dir, name)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'{path} written')
