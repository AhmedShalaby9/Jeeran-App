import 'package:hive_flutter/hive_flutter.dart';

class AppStorage {
  static const String _boxName = 'jeeran_prefs';
  static const String _keyFirstTimeUser = 'is_first_time_user';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyLanguage = 'language';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  // Onboarding
  static bool get isFirstTimeUser =>
      _box.get(_keyFirstTimeUser, defaultValue: true) as bool;

  static Future<void> setFirstTimeUser(bool value) =>
      _box.put(_keyFirstTimeUser, value);

  // Auth
  static String? get authToken => _box.get(_keyAuthToken) as String?;

  static String? get refreshToken => _box.get(_keyRefreshToken) as String?;

  static int? get userId => _box.get(_keyUserId) as int?;

  static String? get userName => _box.get(_keyUserName) as String?;

  static Future<void> saveAuthTokens({
    required String token,
    String? refreshToken,
    int? userId,
    String? userName,
  }) async {
    await _box.put(_keyAuthToken, token);
    if (refreshToken != null) await _box.put(_keyRefreshToken, refreshToken);
    if (userId != null) await _box.put(_keyUserId, userId);
    if (userName != null) await _box.put(_keyUserName, userName);
  }

  static Future<void> saveUserName(String name) =>
      _box.put(_keyUserName, name);

  static Future<void> clearAuth() async {
    await _box.delete(_keyAuthToken);
    await _box.delete(_keyRefreshToken);
    await _box.delete(_keyUserId);
    await _box.delete(_keyUserName);
  }

  static bool get isLoggedIn => authToken != null;

  // Language
  static String? get language => _box.get(_keyLanguage) as String?;

  static Future<void> setLanguage(String value) => _box.put(_keyLanguage, value);
}
