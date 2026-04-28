import os

widgets_dir = 'lib/features/auth/presentation/widgets'

files = {
    'profile_header.dart': '''import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;

  const ProfileHeader({
    super.key,
    required this.step,
    this.onBack,
  });

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
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
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
                        step == 1 ? 'auth.create_profile'.tr() : 'auth.more_about_you'.tr(),
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
                      'Step \ of 2 · \',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSub),
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
''',
    'profile_field_wrapper.dart': '''import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileFieldWrapper extends StatelessWidget {
  final String label;
  final bool required;
  final String? helper;
  final Widget child;

  const ProfileFieldWrapper({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: 0.1,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(helper!, style: const TextStyle(fontSize: 11, color: AppColors.inkMute, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
''',
    'profile_select_field.dart': '''import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileSelectField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const ProfileSelectField({
    super.key,
    this.value,
    this.placeholder = 'Select',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  fontSize: 16,
                  color: value != null ? AppColors.ink : AppColors.inkMute,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.inkSub),
          ],
        ),
      ),
    );
  }
}
''',
    'profile_avatar_picker.dart': '''import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.agentGradientEnd],
                  ),
                ),
                child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'auth.add_profile_photo'.tr(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          Text(
            'auth.optional'.tr(),
            style: const TextStyle(fontSize: 11, color: AppColors.inkMute),
          ),
        ],
      ),
    );
  }
}
''',
    'profile_text_input.dart': '''import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class ProfileTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType type;
  final ValueChanged<String>? onChanged;

  const ProfileTextInput({
    super.key,
    required this.controller,
    required this.hint,
    this.type = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        keyboardType: type,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.inkMute, fontSize: 16),
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
    );
  }
}
''',
    'profile_cta_bar.dart': '''import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';
import 'auth_primary_button.dart';

class ProfileCTABar extends StatelessWidget {
  final int step;
  final bool step1Valid;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  const ProfileCTABar({
    super.key,
    required this.step,
    required this.step1Valid,
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
                    enabled: true,
                    onTap: onComplete,
                  ),
                ),
              ],
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
