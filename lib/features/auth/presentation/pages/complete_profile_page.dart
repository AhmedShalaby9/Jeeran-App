import 'dart:ui' as ui show TextDirection;

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
import '../../../../core/widgets/jv2.dart';
import '../utils/country_codes.dart';
import 'done_page.dart';

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
    return true; // optional step
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
        _gender = user.gender!
            .toLowerCase()
            .replaceAll('-', '_')
            .replaceAll(' ', '_');
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

  void _goToDone() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => DonePage(
          name: _nameCtrl.text.trim(),
          phone: widget.phone.isNotEmpty
              ? widget.phone
              : '$_countryCode ${_phoneCtrl.text.trim()}',
        ),
      ),
      (_) => false,
    );
  }

  void _completeStep2(BuildContext context) {
    if (!_step2Valid) return;
    if (!_isSocialLogin && _gender.isEmpty && _dob == null) {
      _goToDone(); // nothing optional was filled in
      return;
    }
    _submitProfile(context);
  }

  void _submitProfile(BuildContext context) {
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
          countryCode: (phone != null && phone.isNotEmpty)
              ? _countryCode
              : null,
          phoneNumber: (phone != null && phone.isNotEmpty) ? phone : null,
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
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: JV2.navy)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        autofocus: options.length > 5,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(
                            color: AppColors.inkMute,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.inkSub,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F6F8),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.hairline,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.hairline,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (v) => setInner(() {
                          query = v;
                          filtered = options
                              .where(
                                (o) => o.toLowerCase().contains(
                                  query.toLowerCase(),
                                ),
                              )
                              .toList();
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
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.06)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      opt,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
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

  static const _genders = [
    ('male', 'auth.male'),
    ('female', 'auth.female'),
    ('non_binary', 'auth.non_binary'),
    ('prefer_not_to_say', 'auth.prefer_not_to_say'),
  ];

  String _fmtDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileStep1Completed) {
            setState(() => _step = 2);
          } else if (state is AuthProfileCompleted) {
            _goToDone();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: PopScope(
          canPop: _step == 1,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _step == 2) setState(() => _step = 1);
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: JV2.bgDeep,
              body: JV2Ambient(
                intensity: 0.8,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        media.padding.top + 12,
                        24,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          JV2StepBar(step: _step + 1, total: 3),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (_step == 1
                                        ? 'auth.profile_step1_eyebrow'
                                        : (_isSocialLogin
                                              ? 'auth.profile_step2_eyebrow_required'
                                              : 'auth.profile_step2_eyebrow'))
                                    .tr()
                                    .toUpperCase(),
                                style: JV2.eyebrow,
                              ),
                              if (_step == 2 && !_isSocialLogin)
                                GestureDetector(
                                  onTap: _goToDone,
                                  child: Text(
                                    'auth.skip'.tr(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: JV2.inkSub,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                        child: _step == 1 ? _buildStep1() : _buildStep2(),
                      ),
                    ),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        final enabled =
                            !isLoading &&
                            (_step == 1 ? _step1Valid : _step2Valid);
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            18,
                            24,
                            media.padding.bottom + 20,
                          ),
                          child: JV2PrimaryButton(
                            onPressed: enabled
                                ? () => _step == 1
                                      ? _completeStep1(context)
                                      : _completeStep2(context)
                                : null,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        (_step == 1
                                                ? 'auth.continue'
                                                : 'auth.finish')
                                            .tr(),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _step == 1
                                            ? (Directionality.of(context) ==
                                                      ui.TextDirection.rtl
                                                  ? Icons.chevron_left_rounded
                                                  : Icons.chevron_right_rounded)
                                            : Icons.check_rounded,
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final name = _nameCtrl.text.trim();
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: JV2.surface,
                border: Border.all(color: JV2.goldEdge),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0B2A4A),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: initial.isEmpty
                  ? const Icon(
                      Icons.person_outline_rounded,
                      size: 34,
                      color: JV2.inkMute,
                    )
                  : Text(
                      initial,
                      style: JV2
                          .display(context, 30)
                          .copyWith(color: JV2.inkMute),
                    ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [JV2.goldHi, Color(0xFFA67428)],
                  ),
                  border: Border.all(color: JV2.surface, width: 2.5),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'auth.add_photo_title'.tr(),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: JV2.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'auth.add_photo_sub'.tr(),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: JV2.inkMute,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    final hasPhone = widget.phone.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('auth.profile_step1_title'.tr(), style: JV2.display(context, 32)),
        const SizedBox(height: 26),
        _buildAvatar(),
        const SizedBox(height: 26),
        JV2Field(
          label: 'auth.full_name'.tr(),
          controller: _nameCtrl,
          placeholder: 'auth.name_hint'.tr(),
          readOnly: _isSocialLogin && _nameCtrl.text.trim().isNotEmpty,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        JV2Field(
          label: 'auth.email'.tr(),
          controller: _emailCtrl,
          placeholder: 'auth.email_hint'.tr(),
          hint: 'auth.email_helper'.tr(),
          keyboardType: TextInputType.emailAddress,
          readOnly: _isSocialLogin && _emailCtrl.text.trim().isNotEmpty,
          onChanged: (_) => setState(() {}),
        ),
        if (!_isSocialLogin && hasPhone) ...[
          const SizedBox(height: 18),
          JV2Field(
            label: 'auth.mobile'.tr(),
            text: widget.phone,
            readOnly: true,
            suffix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 13,
                  color: JV2.success,
                ),
                const SizedBox(width: 5),
                Text(
                  'auth.verified'.tr(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: JV2.success,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('auth.profile_step2_title'.tr(), style: JV2.display(context, 32)),
        const SizedBox(height: 10),
        Text('auth.profile_step2_sub'.tr(), style: JV2.sub),
        const SizedBox(height: 28),
        Text(
          'auth.gender'.tr().toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: JV2.inkMute,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, labelKey) in _genders)
              GestureDetector(
                onTap: () => setState(() => _gender = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _gender == value ? JV2.goldFilm : JV2.fillFaint,
                    border: Border.all(
                      color: _gender == value ? JV2.goldEdge : JV2.line,
                    ),
                  ),
                  child: Text(
                    labelKey.tr(),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _gender == value ? JV2.gold : JV2.inkSub,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        JV2Field(
          label: 'auth.date_of_birth'.tr(),
          placeholder: 'auth.dob_hint'.tr(),
          text: _dob == null ? null : _fmtDob(_dob!),
          onTap: _pickDate,
          suffix: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: JV2.inkMute,
          ),
        ),
        if (_isSocialLogin) ...[
          const SizedBox(height: 28),
          JV2Field(
            label: 'auth.country'.tr(),
            placeholder: 'auth.select_country'.tr(),
            text: _country,
            hint: 'auth.country_hint'.tr(),
            onTap: () => _showPicker(
              title: 'auth.country'.tr(),
              options: kCountryCodeMap.keys.toList(),
              current: _country,
              onSelect: (v) => setState(() {
                _country = v;
                _countryCode = kCountryCodeMap[v] ?? _countryCode;
              }),
            ),
            suffix: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: JV2.inkMute,
            ),
          ),
          const SizedBox(height: 28),
          JV2Field(
            label: 'auth.phone_number'.tr(),
            controller: _phoneCtrl,
            placeholder: 'auth.phone_hint'.tr(),
            hint: 'auth.phone_required_helper'.tr(),
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            prefix: Container(
              padding: const EdgeInsetsDirectional.only(end: 11),
              decoration: const BoxDecoration(
                border: BorderDirectional(end: BorderSide(color: JV2.line)),
              ),
              child: Text(
                _countryCode,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: JV2.inkSub,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
