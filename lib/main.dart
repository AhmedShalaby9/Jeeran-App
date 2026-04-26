import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/storage/app_storage.dart';
import 'core/utils/app_colors.dart';
import 'core/utils/app_strings.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setEnvironment(AppEnvironment.staging);
  await AppStorage.init();
  await di.init();
  runApp(const JeeranApp());
}

class JeeranApp extends StatelessWidget {
  const JeeranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          iconTheme: IconThemeData(color: AppColors.onBackground),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.grey.withValues(alpha: 0.12),
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
