enum AppEnvironment { staging, production }

class AppConfig {
  static AppEnvironment _env = AppEnvironment.staging;

  static void setEnvironment(AppEnvironment env) => _env = env;

  static AppEnvironment get environment => _env;

  static String get baseUrl => switch (_env) {
        AppEnvironment.staging => 'http://api-stg.jeeran-realestate.com/api',
        AppEnvironment.production => 'http://api.jeeran-realestate.com/api',
      };

  static bool get isProduction => _env == AppEnvironment.production;

  static bool get isStaging => _env == AppEnvironment.staging;
}
