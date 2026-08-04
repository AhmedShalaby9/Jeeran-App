import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../widgets/profile_avatar_picker.dart';
import '../widgets/profile_cta_bar.dart';
import '../widgets/profile_field_wrapper.dart';
import '../widgets/profile_header.dart';
import '../utils/country_codes.dart';
import '../widgets/profile_select_field.dart';
import '../widgets/profile_text_input.dart';

class CompleteProfilePage extends StatefulWidget {
  final String phone;
  final User? initialUser;
  const CompleteProfilePage({super.key, required this.phone, this.initialUser});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  int _step = 1;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = '';
  DateTime? _dob;
  String _country = 'Egypt';
  String _countryCode = '+20';

  bool get _isSocialLogin => widget.initialUser?.isSocialLogin ?? false;

  bool get _step1Valid =>
      _nameCtrl.text.trim().length >= 2 && _emailCtrl.text.contains('@');

  bool get _step2Valid {
    if (_isSocialLogin) {
      return _country.isNotEmpty && _phoneCtrl.text.trim().isNotEmpty;
    }
    return _gender.isNotEmpty && _dob != null;
  }

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    if (user != null) {
      if (user.name != null && user.name!.isNotEmpty) {
        _nameCtrl.text = user.name!;
      }
      if (user.email != null && user.email!.isNotEmpty) {
        _emailCtrl.text = user.email!;
      }
      if (user.gender != null && user.gender!.isNotEmpty) {
        _gender = user.gender!;
      }
      if (user.dob != null) {
        _dob = user.dob;
      }
      if (user.country != null && user.country!.isNotEmpty) {
        _country = user.country!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneCtrl.text = user.phoneNumber!;
      }
      if (user.countryCode != null && user.countryCode!.isNotEmpty) {
        _countryCode = user.countryCode!;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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

    if (_isSocialLogin && _countryCode == '+20') {
      final phone = '$_countryCode${_phoneCtrl.text.trim()}';
      context.read<AuthBloc>().add(AuthSendProfileOtpEvent(phone));
    } else {
      _submitProfile(context, null);
    }
  }

  void _submitProfile(BuildContext context, String? otp) {
    final phone = _isSocialLogin ? _phoneCtrl.text.trim() : null;
    context.read<AuthBloc>().add(
      AuthCompleteProfileEvent(
        CompleteProfileParams(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          gender: _gender.isEmpty ? null : _gender,
          dob: _dob,
          preferredLanguage: context.locale.languageCode,
          country: _isSocialLogin ? _country : null,
          countryCode: (phone != null && phone.isNotEmpty) ? _countryCode : null,
          phoneNumber: (phone != null && phone.isNotEmpty) ? phone : null,
          otp: otp,
        ),
        isStep1: false,
      ),
    );
  }

  void _showOtpBottomSheet(BuildContext context) {
    final bloc = context.read<AuthBloc>();
    final phone = '$_countryCode${_phoneCtrl.text.trim()}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _OtpVerificationSheet(
          phone: phone,
          onVerified: (otp) {
            Navigator.pop(context);
            _submitProfile(context, otp);
          },
        ),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (_, setState) {
          var query = '';
          var filtered = options;
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) => StatefulBuilder(
              builder: (_, setInner) {
                return Column(
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
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        autofocus: options.length > 5,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(color: AppColors.inkMute, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.inkSub, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF5F6F8),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.hairline, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.hairline, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (v) => setInner(() {
                          query = v;
                          filtered = options.where((o) => o.toLowerCase().contains(query.toLowerCase())).toList();
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final opt = filtered[i];
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
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          );
        },
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
          } else if (state is AuthProfileOtpSent) {
            _showOtpBottomSheet(context);
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
                      showSkip: !_isSocialLogin,
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
    final hasPhone = widget.phone.isNotEmpty;
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
            readOnly: _isSocialLogin && _nameCtrl.text.trim().isNotEmpty,
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
            readOnly: _isSocialLogin && _emailCtrl.text.trim().isNotEmpty,
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (!_isSocialLogin && hasPhone)
          ProfileFieldWrapper(
            label: 'auth.phone'.tr(),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairline, width: 1.5),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.phone,
                  style: const TextStyle(fontSize: 16, color: AppColors.inkSub),
                ),
              ),
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
        if (_isSocialLogin) ...[
          ProfileFieldWrapper(
            label: 'auth.country'.tr(),
            required: true,
            child: ProfileSelectField(
              value: _country,
              placeholder: 'auth.select_country'.tr(),
              onTap: () => _showPicker(
                title: 'auth.country'.tr(),
                options: kCountryCodeMap.keys.toList(),
                current: _country,
                onSelect: (v) => setState(() {
                  _country = v;
                  _countryCode = kCountryCodeMap[v] ?? _countryCode;
                }),
              ),
            ),
          ),
          ProfileFieldWrapper(
            label: 'auth.phone_number'.tr(),
            required: true,
            helper: 'auth.phone_required_helper'.tr(),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairline, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.hairline, width: 1.5),
                      ),
                    ),
                    child: Text(
                      _countryCode,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'auth.phone_hint'.tr(),
                        hintStyle: const TextStyle(color: AppColors.inkMute, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      style: const TextStyle(fontSize: 16, color: AppColors.ink),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OtpVerificationSheet extends StatefulWidget {
  final String phone;
  final ValueChanged<String> onVerified;

  const _OtpVerificationSheet({
    required this.phone,
    required this.onVerified,
  });

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet> {
  final _otpCtrl = TextEditingController();
  Timer? _timer;
  int _countdown = 60;

  bool get _canVerify => _otpCtrl.text.trim().length == 6;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _resendOtp() {
    context.read<AuthBloc>().add(AuthSendProfileOtpEvent(widget.phone));
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('auth.otp_sent'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + bottomPad + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'auth.verify_phone'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'auth.otp_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkSub,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.phone,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 12,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'auth.otp_hint'.tr(),
                hintStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                  color: AppColors.inkMute.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F6F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.hairline, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.hairline, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _countdown == 0 ? _resendOtp : null,
              child: Text(
                _countdown > 0
                    ? '${'auth.resend_code'.tr()} (${_countdown}s)'
                    : 'auth.resend_code'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _countdown > 0 ? AppColors.inkMute : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _canVerify && !isLoading
                        ? () => widget.onVerified(_otpCtrl.text.trim())
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'auth.verify'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
