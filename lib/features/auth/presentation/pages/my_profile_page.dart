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

class _MyProfilePageState extends State<MyProfilePage>
    with SingleTickerProviderStateMixin {
  // ── controllers ────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  // ── form state ──────────────────────────────────────────────────
  String _gender = '';
  DateTime? _dob;
  final String _country = 'Egypt';
  User? _user;

  // ── view / edit toggle ──────────────────────────────────────────
  bool _isEditing = false;

  // ── animation ──────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  // ── helpers ─────────────────────────────────────────────────────
  bool get _canSave =>
      _nameCtrl.text.trim().length >= 2 &&
      _emailCtrl.text.contains('@') &&
      _gender.isNotEmpty &&
      _dob != null;

  String get _formattedDob {
    if (_dob == null) return '';
    return '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-'
        '${_dob!.day.toString().padLeft(2, '0')}';
  }

  void _populateFromUser(User user) {
    _user = user;
    _nameCtrl.text = user.name ?? '';
    _emailCtrl.text = user.email ?? '';
    _gender = user.gender ?? '';
    _dob = user.dob;
    _referralCtrl.text = user.referralCode ?? '';
  }

  void _enterEdit() {
    setState(() => _isEditing = true);
    _animCtrl.forward(from: 0);
  }

  void _cancelEdit() {
    // restore original values
    if (_user != null) _populateFromUser(_user!);
    setState(() => _isEditing = false);
    _animCtrl.reverse();
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  // ── date picker ─────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // ── bottom-sheet picker ─────────────────────────────────────────
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
            ...options.map((opt) {
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

  // ── save ────────────────────────────────────────────────────────
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
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthGetMeEvent()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthMeLoaded) {
            _populateFromUser(state.user);
            setState(() {});
          } else if (state is AuthProfileUpdated) {
            _populateFromUser(state.user);
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('profile.saved'.tr())),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _isEditing
                        ? _EditForm(
                            key: const ValueKey('edit'),
                            nameCtrl: _nameCtrl,
                            emailCtrl: _emailCtrl,
                            referralCtrl: _referralCtrl,
                            gender: _gender,
                            dob: _dob,
                            formattedDob: _formattedDob,
                            country: _country,
                            user: _user,
                            canSave: _canSave,
                            isLoading: isLoading,
                            onGenderTap: () => _showPicker(
                              title: 'auth.gender'.tr(),
                              options: [
                                'auth.male'.tr(),
                                'auth.female'.tr(),
                                'auth.prefer_not_to_say'.tr(),
                              ],
                              current: _gender,
                              onSelect: (v) => setState(() => _gender = v),
                            ),
                            onDobTap: _pickDate,
                            onChanged: () => setState(() {}),
                            onSave: () => _save(context),
                          )
                        : _ProfileView(
                            key: const ValueKey('view'),
                            user: _user,
                            isLoading: state is AuthLoading,
                            onEdit: _enterEdit,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          // Back / Cancel button
          GestureDetector(
            onTap: _isEditing ? _cancelEdit : () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navButtonBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _isEditing
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditing ? 'profile.edit_title'.tr() : 'profile.title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Edit button (view mode only)
          if (!_isEditing)
            GestureDetector(
              onTap: _enterEdit,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  'profile.edit'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  VIEW MODE
// ══════════════════════════════════════════════════════════════════
class _ProfileView extends StatelessWidget {
  final User? user;
  final bool isLoading;
  final VoidCallback onEdit;

  const _ProfileView({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = user?.name ?? AppStorage.userName ?? '—';
    final phone = user?.phone ?? '—';
    final email = user?.email;
    final gender = user?.gender;
    final dob = user?.dob;
    final country = user?.country ?? 'Egypt';
    final userType = user?.userType ?? AppStorage.userType;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── avatar card ──────────────────────────────────────────
          _AvatarBanner(
            name: name,
            phone: phone,
            avatarUrl: user?.avatar,
            userType: userType,
          ),

          const SizedBox(height: 12),

          // ── info section ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('profile.personal_info'.tr()),
                _InfoCard(rows: [
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'auth.full_name'.tr(),
                    value: name,
                  ),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'auth.phone'.tr(),
                    value: phone,
                  ),
                  if (email != null && email.isNotEmpty)
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'auth.email'.tr(),
                      value: email,
                    ),
                ]),

                const SizedBox(height: 16),
                _sectionLabel('profile.details'.tr()),
                _InfoCard(rows: [
                  if (gender != null && gender.isNotEmpty)
                    _InfoRow(
                      icon: Icons.wc_outlined,
                      label: 'auth.gender'.tr(),
                      value: gender,
                    ),
                  if (dob != null)
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'auth.date_of_birth'.tr(),
                      value:
                          '${dob.year}-${dob.month.toString().padLeft(2, '0')}-'
                          '${dob.day.toString().padLeft(2, '0')}',
                    ),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'auth.country'.tr(),
                    value: country,
                  ),
                ]),

                // empty-state hint
                if ((email == null || email.isEmpty) ||
                    gender == null ||
                    dob == null) ...[
                  const SizedBox(height: 16),
                  _CompleteProfileBanner(onTap: onEdit),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMute,
            letterSpacing: 1.2,
          ),
        ),
      );
}

// ── avatar banner ────────────────────────────────────────────────
class _AvatarBanner extends StatelessWidget {
  final String name;
  final String phone;
  final String? avatarUrl;
  final String? userType;

  const _AvatarBanner({
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        children: [
          // avatar circle
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSub),
          ),
          if (userType != null && userType!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: userType == 'seller'
                    ? AppColors.tagGoldBg
                    : AppColors.tagPrimaryBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userType!.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: userType == 'seller'
                      ? AppColors.tagGoldFg
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── info card ────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isLast = i == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(row.icon, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.inkMute,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.value,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 64,
                  color: AppColors.hairline,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
}

// ── complete profile banner ──────────────────────────────────────
class _CompleteProfileBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _CompleteProfileBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'profile.complete_hint'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  EDIT FORM
// ══════════════════════════════════════════════════════════════════
class _EditForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController referralCtrl;
  final String gender;
  final DateTime? dob;
  final String formattedDob;
  final String country;
  final User? user;
  final bool canSave;
  final bool isLoading;
  final VoidCallback onGenderTap;
  final VoidCallback onDobTap;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  const _EditForm({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.referralCtrl,
    required this.gender,
    required this.dob,
    required this.formattedDob,
    required this.country,
    required this.user,
    required this.canSave,
    required this.isLoading,
    required this.onGenderTap,
    required this.onDobTap,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar picker
                const ProfileAvatarPicker(),
                const SizedBox(height: 24),

                ProfileFieldWrapper(
                  label: 'auth.full_name'.tr(),
                  required: true,
                  child: ProfileTextInput(
                    controller: nameCtrl,
                    hint: 'auth.name_hint'.tr(),
                    onChanged: (_) => onChanged(),
                  ),
                ),

                ProfileFieldWrapper(
                  label: 'auth.email'.tr(),
                  required: true,
                  child: ProfileTextInput(
                    controller: emailCtrl,
                    hint: 'auth.email_hint'.tr(),
                    type: TextInputType.emailAddress,
                    onChanged: (_) => onChanged(),
                  ),
                ),

                // Phone — read-only
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
                    alignment: Alignment.centerLeft,
                    child: Text(
                      user?.phone ?? AppStorage.userName ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.inkMute,
                      ),
                    ),
                  ),
                ),

                ProfileFieldWrapper(
                  label: 'auth.gender'.tr(),
                  required: true,
                  child: ProfileSelectField(
                    value: gender.isEmpty ? null : gender,
                    placeholder: 'auth.select_gender'.tr(),
                    onTap: onGenderTap,
                  ),
                ),

                ProfileFieldWrapper(
                  label: 'auth.date_of_birth'.tr(),
                  required: true,
                  child: GestureDetector(
                    onTap: onDobTap,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.hairline, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dob == null
                                  ? 'auth.select_date'.tr()
                                  : formattedDob,
                              style: TextStyle(
                                fontSize: 16,
                                color: dob == null
                                    ? AppColors.inkMute
                                    : AppColors.ink,
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
                    alignment: Alignment.centerLeft,
                    child: Text(
                      country,
                      style: const TextStyle(fontSize: 16, color: AppColors.ink),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── Save bar ─────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: IgnorePointer(
              ignoring: isLoading,
              child: FilledButton(
                onPressed: canSave ? onSave : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.inkMute.withValues(alpha: 0.3),
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
        ),
      ],
    );
  }
}
