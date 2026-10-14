/// "15.9M", "1.63B", "347K" — prices in lists, so a 10-digit price never breaks a card.
String fmtShort(num n) {
  String trim(double v, int digits) {
    final s = v.toStringAsFixed(digits);
    return s.contains('.') ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '') : s;
  }

  if (n >= 1e9) return '${trim(n / 1e9, 2)}B';
  if (n >= 1e6) return '${trim(n / 1e6, n >= 1e8 ? 0 : 1)}M';
  if (n >= 1e3) return '${(n / 1e3).round()}K';
  return n.round().toString();
}

/// "11,700,000" — the full figure, on the page itself.
String fmtFull(num n) => n.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// "11.7M – 16M", or one figure when both ends are the same.
String rangeShort(num a, num b) => a == b ? fmtShort(a) : '${fmtShort(a)} – ${fmtShort(b)}';

/// "83–84" (the unit follows from the caller), or one figure.
String rangeNum(num a, num b) {
  String f(num v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  return a == b ? f(a) : '${f(a)}–${f(b)}';
}
