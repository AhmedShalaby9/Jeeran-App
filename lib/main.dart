import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/observers/app_bloc_observer.dart';
import 'core/services/notification_service.dart';
import 'core/storage/app_storage.dart';
import 'core/utils/app_colors.dart';
import 'core/utils/app_strings.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setEnvironment(AppEnvironment.staging);
  await AppStorage.init();
  await NotificationService.instance.init();
  await EasyLocalization.ensureInitialized();
  await di.init();
  Bloc.observer = AppBlocObserver();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: AppStorage.language != null
          ? Locale(AppStorage.language!)
          : const Locale('en'),
      child: const JeeranApp(),
    ),
  );
}

class JeeranApp extends StatelessWidget {
  const JeeranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: _buildTheme(context),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final textTheme = isArabic
        ? GoogleFonts.cairoTextTheme()
        : GoogleFonts.ubuntuTextTheme();

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
      textTheme: textTheme,
      fontFamily: isArabic ? 'Cairo' : 'Ubuntu',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.onBackground,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
        iconTheme: const IconThemeData(color: AppColors.onBackground),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey.withValues(alpha: 0.12),
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
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
    );
  }
}
