enum AppEnvironment { staging, production }

class AppConfig {
  static AppEnvironment _env = AppEnvironment.staging;

  static void setEnvironment(AppEnvironment env) => _env = env;

  static AppEnvironment get environment => _env;

  static String get baseUrl => switch (_env) {
        AppEnvironment.staging => 'http://api-stg.jeeran-realestate.com/api',
        AppEnvironment.production => 'http://api.jeeran-realestate.com/api',
      };

  /// Public Mapbox token (pk.…). Not kept in the source (GitHub's push protection blocks it): pass it at build time,
  ///   flutter run --dart-define-from-file=env/dart_defines.json
  /// (copy env/dart_defines.example.json and fill it in; the real file is git-ignored).
  static const mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

  static bool get isProduction => _env == AppEnvironment.production;

  static bool get isStaging => _env == AppEnvironment.staging;
}
