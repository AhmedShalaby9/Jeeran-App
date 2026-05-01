import 'package:easy_localization/easy_localization.dart';

// ── Property Type ─────────────────────────────────────────────────────────────

enum PropertyType {
  villa,
  apartment,
  chalet,
  marinaApartment,
  clinic,
  office,
  shop,
  land,
  studio,
  duplex;

  /// The raw string sent to / received from the backend.
  String get apiKey => switch (this) {
        villa => 'villa',
        apartment => 'apartment',
        chalet => 'chalet',
        marinaApartment => 'marina_apartment',
        clinic => 'clinic',
        office => 'office',
        shop => 'shop',
        land => 'land',
        studio => 'studio',
        duplex => 'duplex',
      };

  String get _translationKey => 'type.$apiKey';

  /// Translated display label (uses current app locale).
  String label() => _translationKey.tr();

  /// Parse from backend string; returns null for unknown values.
  static PropertyType? fromKey(String? key) => switch (key) {
        'villa' => villa,
        'apartment' => apartment,
        'chalet' => chalet,
        'marina_apartment' => marinaApartment,
        'clinic' => clinic,
        'office' => office,
        'shop' => shop,
        'land' => land,
        'studio' => studio,
        'duplex' => duplex,
        _ => null,
      };

  /// All values as selectable options for UI pickers.
  static List<PropertyType> get options => values;
}

// ── Property Status ───────────────────────────────────────────────────────────

enum PropertyStatus {
  forSale,
  forRent,
  forRentFurnished;

  /// The raw string sent to / received from the backend.
  String get apiKey => switch (this) {
        forSale => 'for_sale',
        forRent => 'for_rent',
        forRentFurnished => 'for_rent_furnished',
      };

  String get _translationKey => 'status.$apiKey';

  /// Translated display label.
  String label() => _translationKey.tr();

  /// Parse from backend string; returns null for unknown values.
  static PropertyStatus? fromKey(String? key) => switch (key) {
        'for_sale' => forSale,
        'for_rent' => forRent,
        'for_rent_furnished' => forRentFurnished,
        _ => null,
      };

  static List<PropertyStatus> get options => values;
}

// ── Country ───────────────────────────────────────────────────────────────────

enum PropertyCountry {
  egypt;

  /// The raw string sent to / received from the backend.
  String get apiKey => switch (this) {
        egypt => 'egypt',
      };

  String get _translationKey => 'location.country.$apiKey';

  /// Translated display label.
  String label() => _translationKey.tr();

  /// Parse from backend string; returns null for unknown values.
  static PropertyCountry? fromKey(String? key) => switch (key) {
        'egypt' => egypt,
        _ => null,
      };

  /// States / cities that belong to this country.
  List<PropertyState> get states => switch (this) {
        egypt => [
            PropertyState.cairo,
            PropertyState.northCoast,
            PropertyState.sharmElSheikh,
          ],
      };

  static List<PropertyCountry> get options => values;
}

// ── State / City ──────────────────────────────────────────────────────────────

enum PropertyState {
  cairo,
  northCoast,
  sharmElSheikh;

  /// The raw string sent to / received from the backend.
  String get apiKey => switch (this) {
        cairo => 'cairo',
        northCoast => 'north_coast',
        sharmElSheikh => 'sharm_el_sheikh',
      };

  String get _translationKey => 'location.state.$apiKey';

  /// Translated display label.
  String label() => _translationKey.tr();

  /// Parse from backend string; returns null for unknown values.
  static PropertyState? fromKey(String? key) => switch (key) {
        'cairo' => cairo,
        'north_coast' => northCoast,
        'sharm_el_sheikh' => sharmElSheikh,
        _ => null,
      };

  static List<PropertyState> get options => values;
}
