import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/property.dart';
import '../entities/property_filter_params.dart';

abstract class PropertyRepository {
  Future<Either<Failure, List<Property>>> getProperties(
    PropertyFilterParams params,
  );
  Future<Either<Failure, List<Property>>> getMyProperties(
    PropertyFilterParams params,
  );
  Future<Either<Failure, List<Property>>> getSimilarProperties(
    int propertyId, {
    int page = 1,
    int limit = 20,
  });
}
