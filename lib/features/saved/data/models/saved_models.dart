import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:equatable/equatable.dart';

import '../../../projects/data/models/project_model.dart';
import '../../../properties/data/models/property_model.dart';

/// Tab counts + what the summary line says ("1 price drop, 1 sold").
class SavedCounts extends Equatable {
  final int listings;
  final int compounds;
  final int developers;
  final int priceDrops;
  final int sold;
  final int unavailable;
  final int freshCompounds;
  final int developerProjects;

  const SavedCounts({
    this.listings = 0,
    this.compounds = 0,
    this.developers = 0,
    this.priceDrops = 0,
    this.sold = 0,
    this.unavailable = 0,
    this.freshCompounds = 0,
    this.developerProjects = 0,
  });

  factory SavedCounts.fromJson(Map<String, dynamic> j) => SavedCounts(
    listings: (j['listings'] as num?)?.toInt() ?? 0,
    compounds: (j['compounds'] as num?)?.toInt() ?? 0,
    developers: (j['developers'] as num?)?.toInt() ?? 0,
    priceDrops: (j['price_drops'] as num?)?.toInt() ?? 0,
    sold: (j['sold'] as num?)?.toInt() ?? 0,
    unavailable: (j['unavailable'] as num?)?.toInt() ?? 0,
    freshCompounds: (j['fresh_compounds'] as num?)?.toInt() ?? 0,
    developerProjects: (j['developer_projects'] as num?)?.toInt() ?? 0,
  );

  SavedCounts copyWith({int? listings, int? compounds, int? developers}) => SavedCounts(
    listings: listings ?? this.listings,
    compounds: compounds ?? this.compounds,
    developers: developers ?? this.developers,
    priceDrops: priceDrops,
    sold: sold,
    unavailable: unavailable,
    freshCompounds: freshCompounds,
    developerProjects: developerProjects,
  );

  @override
  List<Object?> get props =>
      [listings, compounds, developers, priceDrops, sold, unavailable, freshCompounds, developerProjects];
}

/// A saved listing: the property plus how it has moved since it was saved.
class SavedListing extends Equatable {
  final PropertyModel property;
  final double priceChange; // negative = dropped since saving
  final String availability; // available | sold | unavailable

  const SavedListing({
    required this.property,
    required this.priceChange,
    required this.availability,
  });

  bool get isSold => availability == 'sold';
  bool get isGone => availability != 'available';
  bool get hasDropped => !isGone && priceChange < 0;

  factory SavedListing.fromJson(Map<String, dynamic> j) => SavedListing(
    property: PropertyModel.fromJson(j),
    priceChange: (j['price_change'] as num?)?.toDouble() ?? 0,
    availability: j['availability'] as String? ?? 'available',
  );

  @override
  List<Object?> get props => [property, priceChange, availability];
}

/// The latest news item linked to a followed compound / developer.
class SavedUpdate extends Equatable {
  final int id;
  final String title;
  final bool isFresh;

  const SavedUpdate({required this.id, required this.title, required this.isFresh});

  static SavedUpdate? tryParse(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    if (id is! int) return null;
    return SavedUpdate(
      id: id,
      title: raw['title'] as String? ?? '',
      isFresh: raw['is_fresh'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, isFresh];
}

class SavedCompound extends Equatable {
  final ProjectModel project; // carries developer, area, min_price, units_count
  final SavedUpdate? latestUpdate;

  const SavedCompound({required this.project, this.latestUpdate});

  bool get isFresh => latestUpdate?.isFresh ?? false;

  factory SavedCompound.fromJson(Map<String, dynamic> j) => SavedCompound(
    project: ProjectModel.fromJson(j),
    latestUpdate: SavedUpdate.tryParse(j['latest_update']),
  );

  @override
  List<Object?> get props => [project, latestUpdate];
}

class SavedDeveloper extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? logo;
  final bool isVerified;
  final int projectsCount;
  final int listingsCount;
  final SavedUpdate? latestUpdate;

  const SavedDeveloper({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.logo,
    this.isVerified = false,
    this.projectsCount = 0,
    this.listingsCount = 0,
    this.latestUpdate,
  });

  String get name => nameEn.isNotEmpty ? nameEn : nameAr;

  /// "TMG" for Talaat Moustafa Group, "EM" for Emaar Misr — the monogram in the logo tile.
  String get short {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.take(2).toString().toUpperCase();
    return words.take(3).map((w) => w.characters.first).join().toUpperCase();
  }

  factory SavedDeveloper.fromJson(Map<String, dynamic> j) => SavedDeveloper(
    id: j['id'] as int,
    nameAr: j['name_ar'] as String? ?? '',
    nameEn: j['name_en'] as String? ?? '',
    logo: j['logo'] as String?,
    isVerified: j['is_verified'] as bool? ?? false,
    projectsCount: (j['projects_count'] as num?)?.toInt() ?? 0,
    listingsCount: (j['listings_count'] as num?)?.toInt() ?? 0,
    latestUpdate: SavedUpdate.tryParse(j['latest_update']),
  );

  @override
  List<Object?> get props => [id, nameAr, nameEn, logo, isVerified, projectsCount, listingsCount, latestUpdate];
}
