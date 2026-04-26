import 'package:flutter/material.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/utils/app_colors.dart';

class HomeGreetingWidget extends StatelessWidget {
  const HomeGreetingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final greeting = (AppStorage.isLoggedIn && (AppStorage.userName ?? '').isNotEmpty)
        ? 'Hello, ${AppStorage.userName}'
        : 'Hello';

    return Text(
      greeting,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
