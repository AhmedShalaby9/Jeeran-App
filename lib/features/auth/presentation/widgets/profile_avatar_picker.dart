import 'package:flutter/material.dart';
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
