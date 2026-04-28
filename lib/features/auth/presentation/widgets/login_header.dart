import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28, topPad + 28, 28, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/icon/icon.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 52),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'auth.welcome_back'.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'auth.enter_phone'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSub, height: 1.4),
          ),
        ],
      ),
    );
  }
}
