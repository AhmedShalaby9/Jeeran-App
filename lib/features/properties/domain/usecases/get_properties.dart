import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property.dart';
import '../entities/property_filter_params.dart';
import '../repositories/property_repository.dart';

class GetProperties implements UseCase<List<Property>, PropertyFilterParams> {
  final PropertyRepository repository;

  GetProperties(this.repository);

  @override
  Future<Either<Failure, List<Property>>> call(PropertyFilterParams params) {
    return repository.getProperties(params);
  }
}
