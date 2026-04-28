import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../properties/domain/entities/property.dart';

abstract class FavoritesRepository {
  Future<Either<Failure, List<Property>>> getFavorites();
  Future<Either<Failure, void>> addFavorite(int propertyId);
  Future<Either<Failure, void>> removeFavorite(int propertyId);
}
