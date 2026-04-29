import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../widgets/profile_avatar_picker.dart';
import '../widgets/profile_cta_bar.dart';
import '../widgets/profile_field_wrapper.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_select_field.dart';
import '../widgets/profile_text_input.dart';

class CompleteProfilePage extends StatefulWidget {
  final String phone;
  const CompleteProfilePage({super.key, required this.phone});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  int _step = 1;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _gender = '';
  DateTime? _dob;
  final String _country = 'Egypt';
  final _referralCtrl = TextEditingController();

  bool get _step1Valid =>
      _nameCtrl.text.trim().length >= 2 && _emailCtrl.text.contains('@');

  bool get _step2Valid => _gender.isNotEmpty && _dob != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  void _completeStep1(BuildContext context) {
    if (!_step1Valid) return;
    context.read<AuthBloc>().add(
      AuthCompleteProfileEvent(
        CompleteProfileParams(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        ),
        isStep1: true,
      ),
    );
  }

  void _skipToMain(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
      (_) => false,
    );
  }

  void _completeStep2(BuildContext context) {
    if (!_step2Valid) return;
    context.read<AuthBloc>().add(
      AuthCompleteProfileEvent(
        CompleteProfileParams(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          gender: _gender.isEmpty ? null : _gender,
          dob: _dob,
          preferredLanguage: context.locale.languageCode,
          country: _country,
          referralCode: _referralCtrl.text.isEmpty ? null : _referralCtrl.text,
        ),
        isStep1: false,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _showPicker({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(options.length, (i) {
              final opt = options[i];
              final selected = opt == current;
              return InkWell(
                onTap: () {
                  onSelect(opt);
                  Navigator.pop(context);
                },
                child: Container(
                  color: selected ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(child: Text(opt, style: const TextStyle(fontSize: 15, color: AppColors.ink))),
                      if (selected) const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileStep1Completed) {
            setState(() => _step = 2);
          } else if (state is AuthProfileCompleted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainPage()),
              (_) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              ProfileHeader(
                step: _step,
                onBack: _step == 2 ? () => setState(() => _step = 1) : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _step == 1 ? _buildStep1() : _buildStep2(),
                ),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return IgnorePointer(
                    ignoring: isLoading,
                    child: ProfileCTABar(
                      step: _step,
                      step1Valid: _step1Valid,
                      step2Valid: _step2Valid,
                      onContinue: () => _completeStep1(context),
                      onSkip: () => _skipToMain(context),
                      onComplete: () => _completeStep2(context),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileAvatarPicker(),
        const SizedBox(height: 24),
        ProfileFieldWrapper(
          label: 'auth.full_name'.tr(),
          required: true,
          child: ProfileTextInput(
            controller: _nameCtrl,
            hint: 'auth.name_hint'.tr(),
            onChanged: (_) => setState(() {}),
          ),
        ),
        ProfileFieldWrapper(
          label: 'auth.email'.tr(),
          required: true,
          helper: 'auth.email_helper'.tr(),
          child: ProfileTextInput(
            controller: _emailCtrl,
            hint: 'auth.email_hint'.tr(),
            type: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileFieldWrapper(
          label: 'auth.gender'.tr(),
          child: ProfileSelectField(
            value: _gender.isEmpty ? null : _gender,
            placeholder: 'auth.select_gender'.tr(),
            onTap: () => _showPicker(
              title: 'auth.gender'.tr(),
              options: [
                'auth.male'.tr(),
                'auth.female'.tr(),
                'auth.prefer_not_to_say'.tr(),
              ],
              current: _gender,
              onSelect: (v) => setState(() => _gender = v),
            ),
          ),
        ),
        ProfileFieldWrapper(
          label: 'auth.date_of_birth'.tr(),
          child: GestureDetector(
            onTap: _pickDate,
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
                      _dob == null
                          ? 'auth.select_date'.tr()
                          : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dob == null ? AppColors.inkMute : AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.inkSub),
                ],
              ),
            ),
          ),
        ),
        ProfileFieldWrapper(
          label: 'auth.country'.tr(),
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
                    _country,
                    style: const TextStyle(fontSize: 16, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        ProfileFieldWrapper(
          label: 'auth.referral_code'.tr(),
          helper: 'auth.referral_helper'.tr(),
          child: Stack(
            children: [
              ProfileTextInput(
                controller: _referralCtrl,
                hint: 'auth.referral_hint'.tr(),
                onChanged: (_) => setState(() {}),
              ),
              if (_referralCtrl.text.isNotEmpty)
                Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                      child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
