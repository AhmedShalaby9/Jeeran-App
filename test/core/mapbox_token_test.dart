import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/core/services/app_settings_service.dart';

void main() {
  tearDown(() => AppSettingsService.instance.settings = null);

  test('the Mapbox token comes from the settings the server sends', () {
    AppSettingsService.instance.settings = AppSettings.fromJson({'mapbox_token': ' pk.from-the-server '});
    expect(AppSettingsService.instance.mapboxToken, 'pk.from-the-server'); // trimmed
  });

  test('without it from the server there is no token (and no crash) unless a build-time fallback was given', () {
    AppSettingsService.instance.settings = null; // settings not loaded yet
    expect(AppSettingsService.instance.mapboxToken, isEmpty);
    AppSettingsService.instance.settings = AppSettings.fromJson({'mapbox_token': null});
    expect(AppSettingsService.instance.mapboxToken, isEmpty);
    AppSettingsService.instance.settings = AppSettings.fromJson({'mapbox_token': '  '});
    expect(AppSettingsService.instance.mapboxToken, isEmpty);
  });
}
