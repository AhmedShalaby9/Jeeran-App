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
  final String? adGenerationPrice;
  final int? adGenerationTrials;
  final bool inReview;
  final bool promoAiAdsVisible;
  final bool promoSellerVisible;
  final int promoAiAdsOrder;
  final int promoSellerOrder;
  final String? aiGuideVideoUrl;
  final bool aiGuideVideoVisible;

  const AppSettings({
    this.minVersionIos,
    this.minVersionAndroid,
    this.appStoreUrl,
    this.googlePlayUrl,
    this.termsEn,
    this.termsAr,
    this.aboutUsEn,
    this.aboutUsAr,
    this.adGenerationPrice,
    this.adGenerationTrials,
    this.inReview = false,
    this.promoAiAdsVisible = true,
    this.promoSellerVisible = true,
    this.promoAiAdsOrder = 1,
    this.promoSellerOrder = 2,
    this.aiGuideVideoUrl,
    this.aiGuideVideoVisible = false,
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
        adGenerationPrice: json['ad_generation_price'] as String?,
        adGenerationTrials: json['ad_generation_trials'] as int?,
        inReview: (json['in_review'] as bool?) ?? false,
        promoAiAdsVisible: (json['promo_ai_ads_visible'] as bool?) ?? true,
        promoSellerVisible: (json['promo_seller_visible'] as bool?) ?? true,
        promoAiAdsOrder: (json['promo_ai_ads_order'] as int?) ?? 1,
        promoSellerOrder: (json['promo_seller_order'] as int?) ?? 2,
        aiGuideVideoUrl: json['ai_guide_video_url'] as String?,
        aiGuideVideoVisible: (json['ai_guide_video_visible'] as bool?) ?? false,
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

  bool get inReview => settings?.inReview ?? false;

  String? terms(String locale) =>
      locale == 'ar' ? settings?.termsAr : settings?.termsEn;

  String? about(String locale) =>
      locale == 'ar' ? settings?.aboutUsAr : settings?.aboutUsEn;

  /// Returns the visible promo banner types sorted by their configured order.
  /// Each entry is either `'ai_ads'` or `'seller'`.
  List<String> get promoBannersOrdered {
    final s = settings;
    final entries = <(int, String)>[];
    if (s == null || s.promoAiAdsVisible) {
      entries.add((s?.promoAiAdsOrder ?? 1, 'ai_ads'));
    }
    if (s == null || s.promoSellerVisible) {
      entries.add((s?.promoSellerOrder ?? 2, 'seller'));
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    return entries.map((e) => e.$2).toList();
  }
}
