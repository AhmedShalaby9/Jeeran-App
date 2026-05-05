class AppUpdateService {
  // Returns true when currentVersion is strictly less than minRequired.
  // Both strings must be semver "major.minor.patch". Returns false on any
  // parse failure so a bad server value never blocks the user.
  static bool isUpdateRequired(String? minRequired, String currentVersion) {
    if (minRequired == null || minRequired.isEmpty) return false;
    final min = _parse(minRequired);
    final cur = _parse(currentVersion);
    if (min == null || cur == null) return false;
    return _lessThan(cur, min);
  }

  static List<int>? _parse(String version) {
    try {
      // Strip any build metadata (e.g. "1.0.0+1" → "1.0.0")
      final clean = version.split('+').first.trim();
      final parts = clean.split('.').map(int.parse).toList();
      if (parts.length != 3) return null;
      return parts;
    } catch (_) {
      return null;
    }
  }

  // Returns true if a < b (element-wise semver comparison).
  static bool _lessThan(List<int> a, List<int> b) {
    for (int i = 0; i < 3; i++) {
      if (a[i] < b[i]) return true;
      if (a[i] > b[i]) return false;
    }
    return false; // equal → no update needed
  }
}
