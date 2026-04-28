import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  final int id;
  final String name;
  final String description;
  final String price;
  final int durationDays;
  final int availableListings;
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.availableListings,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        durationDays,
        availableListings,
        features,
        isActive,
        createdAt,
        updatedAt,
      ];
}
