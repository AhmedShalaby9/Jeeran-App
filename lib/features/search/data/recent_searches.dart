import 'package:hive_flutter/hive_flutter.dart';

import 'search_filters.dart';

/// The last few searches, kept on the device only.
class RecentSearches {
  static const _key = 'recent_searches';
  static const _max = 6;

  static Box get _box => Hive.box('jeeran_prefs');

  static List<SearchFilters> all() {
    try {
      final raw = _box.get(_key);
      if (raw is! List) return const [];
      return raw.whereType<Map>().map(SearchFilters.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Adds [f] to the top (moving an identical earlier entry up). Ignores empty searches.
  static Future<void> add(SearchFilters f) async {
    if (!f.isActive) return;
    try {
      final list = all().where((x) => x != f).toList()..insert(0, f);
      await _box.put(_key, list.take(_max).map((x) => x.toJson()).toList());
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await _box.delete(_key);
    } catch (_) {}
  }
}
