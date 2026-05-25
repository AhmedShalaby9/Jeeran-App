/// Formats a raw price string into a human-readable abbreviated form.
/// Examples:
///   "1300000"  → "1.3M"
///   "500000"   → "500K"
///   "75000"    → "75K"
///   "950"      → "950"
String formatPrice(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final n = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
  if (n == null) return raw;
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    final v = n / 1000;
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}K';
  }
  return n % 1 == 0 ? n.toInt().toString() : raw;
}
