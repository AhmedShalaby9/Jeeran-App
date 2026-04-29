import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/profile_avatar_picker.dart';
import '../widgets/profile_field_wrapper.dart';
import '../widgets/profile_select_field.dart';
import '../widgets/profile_text_input.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  String _gender = '';
  DateTime? _dob;
  final String _country = 'Egypt';
  String _city = '';
  User? _user;

  static const _cities = {
    'Egypt': [
      'Cairo',
      'Giza',
      'Alexandria',
      'New Cairo',
      '6th of October',
      'Sharm El Sheikh',
      'Hurghada',
      'Mansoura',
      'Tanta',
      'Port Said',
      'Suez',
      'Luxor',
      'Aswan',
      'Fayoum',
      'Minya',
      'Assiut',
      'Sohag',
      'Qena',
      'Beni Suef',
      'Damietta',
      'Zagazig',
    ],
  };

  bool get _canSave =>
      _nameCtrl.text.trim().length >= 2 &&
      _emailCtrl.text.contains('@') &&
      _gender.isNotEmpty &&
      _dob != null &&
      _city.isNotEmpty;

  void _populateFromUser(User user) {
    _user = user;
    _nameCtrl.text = user.name ?? '';
    _emailCtrl.text = user.email ?? '';
    _gender = user.gender ?? '';
    _dob = user.dob;
    _city = user.city ?? '';
    _referralCtrl.text = user.referralCode ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
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
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    if (!_canSave) return;
    context.read<AuthBloc>().add(
      AuthUpdateProfileEvent(
        CompleteProfileParams(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          gender: _gender.isEmpty ? null : _gender,
          dob: _dob,
          preferredLanguage: context.locale.languageCode,
          country: _country,
          city: _city.isEmpty ? null : _city,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthGetMeEvent()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthMeLoaded) {
            _populateFromUser(state.user);
          } else if (state is AuthProfileUpdated) {
            _populateFromUser(state.user);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('profile.saved'.tr())));
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _buildForm(),
                  ),
                ),
                _buildSaveBar(context, isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navButtonBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'profile.title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final cityList = _cities[_country] ?? ['Other'];
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
          child: ProfileTextInput(
            controller: _emailCtrl,
            hint: 'auth.email_hint'.tr(),
            type: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
        ),
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _user?.phone ?? AppStorage.userName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.inkMute,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ProfileFieldWrapper(
          label: 'auth.gender'.tr(),
          required: true,
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
          required: true,
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
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.inkSub,
                  ),
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
          label: 'auth.city'.tr(),
          required: true,
          child: ProfileSelectField(
            value: _city.isEmpty ? null : _city,
            placeholder: 'auth.select_city'.tr(),
            onTap: () => _showPicker(
              title: 'auth.city'.tr(),
              options: cityList,
              current: _city,
              onSelect: (v) => setState(() => _city = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveBar(BuildContext context, bool isLoading) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: IgnorePointer(
          ignoring: isLoading,
          child: FilledButton(
            onPressed: _canSave ? () => _save(context) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.inkMute.withValues(alpha: 0.3),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'profile.save'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
