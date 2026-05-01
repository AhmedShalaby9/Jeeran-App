import 'package:flutter/material.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../packages/presentation/pages/packages_destination.dart';

abstract class Tab4Destination {
  const Tab4Destination._();

  static Widget create({required bool isSeller}) {
    if (isSeller) return const PackagesDestination();
    return const FavoritesPage();
  }
}
