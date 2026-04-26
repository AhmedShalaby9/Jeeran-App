import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBar(title: Text('More')),
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
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sign in to access all features',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Sign In',
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

          _SectionHeader(title: 'Account'),
          _MoreTile(icon: Icons.person_outline, label: 'My Profile', onTap: () {}),
          _MoreTile(icon: Icons.home_work_outlined, label: 'My Properties', onTap: () {}),
          _MoreTile(icon: Icons.favorite_border, label: 'Saved Searches', onTap: () {}),
          _MoreTile(icon: Icons.message_outlined, label: 'Messages', onTap: () {}),

          const SizedBox(height: 16),

          _SectionHeader(title: 'Add Listing'),
          _MoreTile(icon: Icons.add_box_outlined, label: 'Add Property', onTap: () {}),

          const SizedBox(height: 16),

          _SectionHeader(title: 'Settings'),
          _MoreTile(icon: Icons.language_outlined, label: 'Language', trailing: 'English', onTap: () {}),
          _MoreTile(icon: Icons.dark_mode_outlined, label: 'Dark Mode', onTap: () {}),
          _MoreTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),

          const SizedBox(height: 16),

          _SectionHeader(title: 'Support'),
          _MoreTile(icon: Icons.info_outline, label: 'About Jeeran', onTap: () {}),
          _MoreTile(icon: Icons.headset_mic_outlined, label: 'Contact Us', onTap: () {}),
          _MoreTile(icon: Icons.policy_outlined, label: 'Privacy Policy', onTap: () {}),
          _MoreTile(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),

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
                  Text(trailing!, style: TextStyle(color: AppColors.grey, fontSize: 13)),
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
