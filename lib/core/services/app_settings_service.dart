import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class AppSettings {
  final String? minVersionIos;
  final String? minVersionAndroid;
  final String? appStoreUrl;
  final String? googlePlayUrl;
  final String? termsEn;
  final String? termsAr;
  final String? aboutUsEn;
  final String? aboutUsAr;

  const AppSettings({
    this.minVersionIos,
    this.minVersionAndroid,
    this.appStoreUrl,
    this.googlePlayUrl,
    this.termsEn,
    this.termsAr,
    this.aboutUsEn,
    this.aboutUsAr,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        minVersionIos: json['min_version_ios'] as String?,
        minVersionAndroid: json['min_version_android'] as String?,
        appStoreUrl: json['app_store_url'] as String?,
        googlePlayUrl: json['google_play_url'] as String?,
        termsEn: json['terms_en'] as String?,
        termsAr: json['terms_ar'] as String?,
        aboutUsEn: json['about_us_en'] as String?,
        aboutUsAr: json['about_us_ar'] as String?,
      );
}

class AppSettingsService {
  AppSettingsService._();
  static final instance = AppSettingsService._();

  AppSettings? settings;

  Future<void> fetch(ApiClient client) async {
    try {
      final response = await client.get(ApiEndpoints.appSettings);
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) settings = AppSettings.fromJson(data);
      }
    } catch (_) {
      // Non-critical — app continues with null settings if offline or error.
    }
  }

  String? terms(String locale) =>
      locale == 'ar' ? settings?.termsAr : settings?.termsEn;

  String? about(String locale) =>
      locale == 'ar' ? settings?.aboutUsAr : settings?.aboutUsEn;
}
