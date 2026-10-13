import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/app_storage.dart';
import '../../core/widgets/jv2.dart';
import '../auth/presentation/pages/login_page.dart';
import '../main/presentation/pages/main_page.dart';
import 'profile_api.dart';
import 'profile_page.dart';

/// The fields behind the profile. Phone and email are how people reach you and how you sign in, so they are
/// shown but not changed here. Pops with the saved [ProfileData].
class EditProfilePage extends StatefulWidget {
  final ProfileData profile;
  final ProfileApi api;
  const EditProfilePage({super.key, required this.profile, required this.api});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _city = TextEditingController(text: widget.profile.city ?? '');
  late final _company = TextEditingController(
    text: widget.profile.company ?? '',
  );
  late final _bio = TextEditingController(text: widget.profile.bio ?? '');
  late String _lang;
  String? _picture;
  bool _busy = false, _dirty = false, _uploading = false;

  ProfileData get _p => widget.profile;

  @override
  void initState() {
    super.initState();
    _picture = _p.picture;
    _lang = _p.language ?? 'en';
    // the app's current language wins when the account never chose one
    if (_p.language == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lang = context.locale.languageCode;
      });
    }
    for (final c in [_name, _city, _company, _bio]) {
      c.addListener(() => setState(() => _dirty = true));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _city, _company, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave => _dirty && !_busy && _name.text.trim().length >= 2;

  void _toast(String key) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(key.tr())));

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _uploading = true);
    try {
      final url = await widget.api.upload(x.path);
      if (mounted) {
        setState(() {
          _picture = url;
          _dirty = true;
        });
      }
    } catch (_) {
      if (mounted) _toast('profile.photo_failed');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final saved = await widget.api.save({
        'name': _name.text.trim(),
        'city': _city.text.trim(),
        'profile_picture': _picture ?? '',
        'preferred_language': _lang,
        if (_p.isSeller) ...{
          'company_name': _company.text.trim(),
          'bio': _bio.text.trim(),
        },
      });
      unawaited(AppStorage.saveUserName(saved.name));
      if (!mounted) return;
      if (_lang != context.locale.languageCode) {
        // a language change rebuilds the whole app so every screen picks it up
        await context.setLocale(Locale(_lang));
        await AppStorage.setLanguage(_lang);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) =>
                AppStorage.isLoggedIn ? const MainPage() : const LoginPage(),
            transitionDuration: Duration.zero,
          ),
          (_) => false,
        );
        return;
      }
      Navigator.pop(context, saved);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('profile.save_failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seller = _p.isSeller;
    return Scaffold(
      backgroundColor: JV2.bgDeep,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              kProfilePad,
              MediaQuery.of(context).padding.top + 10,
              kProfilePad,
              12,
            ),
            decoration: const BoxDecoration(
              color: Color(0xF0FAFBFD),
              border: Border(bottom: BorderSide(color: JV2.line)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  key: const Key('edit-close'),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: JV2.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: JV2.line),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: JV2.ink,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'profile.edit_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: JV2.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 38),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                kProfilePad,
                22,
                kProfilePad,
                28,
              ),
              children: [
                _photoRow(seller),
                const SizedBox(height: 26),
                _section('profile.personal'.tr()),
                _field('profile.full_name'.tr(), _name, key: 'f-name'),
                const SizedBox(height: 16),
                _field('profile.city'.tr(), _city, key: 'f-city'),
                const SizedBox(height: 16),
                Text('profile.app_language'.tr(), style: _label),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final code in const ['en', 'ar']) ...[
                      if (code == 'ar') const SizedBox(width: 8),
                      Expanded(child: _langChip(code)),
                    ],
                  ],
                ),
                const SizedBox(height: 26),
                _section('profile.contact'.tr()),
                _field(
                  'profile.mobile'.tr(),
                  TextEditingController(text: _p.phone ?? ''),
                  readOnly: true,
                  trailing: _p.phone == null ? null : const VerifiedTick(),
                  hint: 'profile.mobile_hint'.tr(),
                ),
                const SizedBox(height: 16),
                _field(
                  'profile.email'.tr(),
                  TextEditingController(text: _p.email ?? ''),
                  readOnly: true,
                  hint: 'profile.email_hint'.tr(),
                ),
                if (seller) ...[
                  const SizedBox(height: 26),
                  _section('profile.seller_profile'.tr()),
                  _field('profile.company'.tr(), _company, key: 'f-company'),
                  const SizedBox(height: 16),
                  _field(
                    'profile.about_you'.tr(),
                    _bio,
                    key: 'f-bio',
                    lines: 4,
                    maxLength: 300,
                    hint: 'profile.about_hint'.tr(
                      args: ['${_bio.text.length}'],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              kProfilePad,
              12,
              kProfilePad,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Color(0xF5FAFBFD),
              border: Border(top: BorderSide(color: JV2.line)),
            ),
            child: JV2PrimaryButton(
              key: const Key('save-profile'),
              onPressed: _canSave ? _save : null,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('profile.save'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  static const _label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: JV2.ink,
  );

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(t.toUpperCase(), style: JV2.eyebrow),
  );

  Widget _photoRow(bool seller) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ProfileAvatar(url: _picture, name: _name.text, size: 76),
            PositionedDirectional(
              end: -2,
              bottom: -2,
              child: GestureDetector(
                key: const Key('change-photo'),
                onTap: _uploading ? null : _pickPhoto,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: JV2.navy,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: _uploading
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
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
              Text('profile.photo'.tr(), style: _label.copyWith(fontSize: 14)),
              const SizedBox(height: 3),
              Text(
                (seller ? 'profile.photo_hint_seller' : 'profile.photo_hint')
                    .tr(),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: JV2.inkSub,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _uploading ? null : _pickPhoto,
                    child: Text(
                      'profile.change'.tr(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: JV2.navy,
                      ),
                    ),
                  ),
                  if ((_picture ?? '').isNotEmpty) ...[
                    const SizedBox(width: 14),
                    GestureDetector(
                      key: const Key('remove-photo'),
                      onTap: () => setState(() {
                        _picture = null;
                        _dirty = true;
                      }),
                      child: Text(
                        'profile.remove'.tr(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: JV2.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _langChip(String code) {
    final on = _lang == code;
    return GestureDetector(
      key: Key('lang-$code'),
      onTap: () => setState(() {
        _lang = code;
        _dirty = true;
      }),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? JV2.navy : JV2.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? JV2.navy : JV2.line),
        ),
        child: Text(
          code == 'en' ? 'English' : 'العربية',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? Colors.white : JV2.ink,
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    String? key,
    bool readOnly = false,
    int lines = 1,
    int? maxLength,
    String? hint,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: _label)),
            ?trailing,
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: lines > 1 ? 4 : 0,
          ),
          decoration: BoxDecoration(
            color: readOnly ? JV2.fillFaint : JV2.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JV2.line),
          ),
          child: TextField(
            key: key == null ? null : Key(key),
            controller: c,
            readOnly: readOnly,
            minLines: lines,
            maxLines: lines,
            maxLength: maxLength,
            textDirection: readOnly ? ui.TextDirection.ltr : null,
            style: TextStyle(
              fontSize: lines > 1 ? 14 : 15,
              height: lines > 1 ? 1.5 : null,
              color: readOnly ? JV2.inkSub : JV2.ink,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              isDense: false,
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 7),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: JV2.inkSub,
            ),
          ),
        ],
      ],
    );
  }
}
