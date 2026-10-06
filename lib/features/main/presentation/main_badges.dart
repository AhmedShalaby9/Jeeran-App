import 'package:flutter/foundation.dart';

/// Tab-bar badges fed by whichever screen knows the value first
/// (the Explore feed sets them; other screens may refine them).
class MainBadges {
  MainBadges._();

  /// Number on the Saved tab.
  static final ValueNotifier<int> savedCount = ValueNotifier<int>(0);

  /// Dot on the You tab — something there needs the user's attention.
  static final ValueNotifier<bool> youAttention = ValueNotifier<bool>(false);
}
