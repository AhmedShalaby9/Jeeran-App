import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/my_profile_page.dart';
import '../../../properties/presentation/pages/add_property_page.dart';
import '../../../seller_request/presentation/bloc/seller_request_bloc.dart';
import '../../../seller_request/presentation/bloc/seller_request_state.dart';
import '../../../seller_request/presentation/widgets/seller_request_tile.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc is provided by MainPage — share the same instance.
        BlocProvider.value(value: context.read<AuthBloc>()),
        BlocProvider(create: (_) => sl<SellerRequestBloc>()),
      ],
      child: const _MoreView(),
    );
  }
}

class _MoreView extends StatelessWidget {
  const _MoreView();

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

  void _showSellerRequestSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'seller_request.success_title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'seller_request.success_message'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inkSub,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('actions.cancel'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SellerRequestBloc, SellerRequestState>(
      listener: (context, state) {
        if (state is SellerRequestSuccess) {
          _showSellerRequestSuccessSheet(context);
        } else if (state is SellerRequestError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('more.title'.tr())),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile card
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthMeLoaded ? state.user : null;
                final displayName =
                    user?.name ?? AppStorage.userName ?? 'more.guest_user'.tr();
                final phone = user?.phone ?? '';

                return Container(
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
                          image: user?.avatar != null
                              ? DecorationImage(
                                  image: NetworkImage(user!.avatar!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user?.avatar == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                phone,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            _SectionHeader(title: 'more.account'.tr()),
            _MoreTile(
              icon: Icons.person_outline,
              label: 'more.my_profile'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyProfilePage()),
              ),
            ),

            const SellerRequestTile(),
            // My Properties + Add Listing — sellers only
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final user = authState is AuthMeLoaded ? authState.user : null;
                final isSeller = user?.isSeller ?? AppStorage.isSeller;
                if (!isSeller) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MoreTile(
                      icon: Icons.home_work_outlined,
                      label: 'more.my_properties'.tr(),
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'more.add_listing'.tr()),
                    _MoreTile(
                      icon: Icons.add_box_outlined,
                      label: 'more.add_property'.tr(),
                      onTap: () => AddPropertyPage.push(context),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            _SectionHeader(title: 'more.settings'.tr()),
            _MoreTile(
              icon: Icons.language_outlined,
              label: 'more.language'.tr(),
              trailing: context.locale.languageCode == 'ar'
                  ? 'language.arabic'.tr()
                  : 'language.english'.tr(),
              onTap: () => _showLanguageSheet(context),
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

            const SizedBox(height: 16),

            // Logout
            if (AppStorage.isLoggedIn)
              _MoreTile(
                icon: Icons.logout_outlined,
                label: 'more.logout'.tr(),
                onTap: () => _onLogout(context),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('more.logout_title'.tr()),
        content: Text('more.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('actions.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppStorage.clearAuth();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            child: Text(
              'actions.logout'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
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
  final VoidCallback? onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    this.onTap,
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
