import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'language.select'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const Divider(height: 20),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: Text('language.english'.tr()),
                trailing: context.locale.languageCode == 'en'
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () async {
                  await context.setLocale(const Locale('en'));
                  await AppStorage.setLanguage('en');
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: Text('language.arabic'.tr()),
                trailing: context.locale.languageCode == 'ar'
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () async {
                  await context.setLocale(const Locale('ar'));
                  await AppStorage.setLanguage('ar');
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('more.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'more.guest_user'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'more.sign_in_prompt'.tr(),
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'more.sign_in'.tr(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionHeader(title: 'more.account'.tr()),
          _MoreTile(
            icon: Icons.person_outline,
            label: 'more.my_profile'.tr(),
            onTap: () => _showLanguageSheet(context),
          ),
          _MoreTile(
            icon: Icons.home_work_outlined,
            label: 'more.my_properties'.tr(),
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.favorite_border,
            label: 'more.saved_searches'.tr(),
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.message_outlined,
            label: 'more.messages'.tr(),
            onTap: () {},
          ),

          const SizedBox(height: 16),

          _SectionHeader(title: 'more.add_listing'.tr()),
          _MoreTile(
            icon: Icons.add_box_outlined,
            label: 'more.add_property'.tr(),
            onTap: () {},
          ),

          const SizedBox(height: 16),

          _SectionHeader(title: 'more.settings'.tr()),
          _MoreTile(
            icon: Icons.language_outlined,
            label: 'more.language'.tr(),
            trailing: context.locale.languageCode == 'ar' ? 'language.arabic'.tr() : 'language.english'.tr(),
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.dark_mode_outlined,
            label: 'more.dark_mode'.tr(),
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.notifications_outlined,
            label: 'more.notifications'.tr(),
            onTap: () {},
          ),

          const SizedBox(height: 16),

          _SectionHeader(title: 'more.support'.tr()),
          _MoreTile(
            icon: Icons.info_outline,
            label: 'more.about'.tr(),
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.headset_mic_outlined,
            label: 'more.contact_us'.tr(),
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.policy_outlined,
            label: 'more.privacy_policy'.tr(),
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.description_outlined,
            label: 'more.terms_of_service'.tr(),
            onTap: () {},
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 15, color: AppColors.onBackground),
        ),
        trailing: trailing != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailing!,
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
                ],
              )
            : Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
