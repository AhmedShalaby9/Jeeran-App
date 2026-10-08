import 'package:url_launcher/url_launcher.dart';

import 'app_settings_service.dart';

/// Every "Call us" button in the app dials the number saved in the dashboard settings.
class ContactCall {
  ContactCall._();

  static String? get number => AppSettingsService.instance.contactPhone;

  /// `tel:` URI for [raw] — keeps digits and a leading plus only.
  static Uri? telUri(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.isEmpty ? null : Uri(scheme: 'tel', path: cleaned);
  }

  static Future<bool> dial() async {
    final uri = telUri(number);
    if (uri == null) return false;
    return launchUrl(uri);
  }
}
