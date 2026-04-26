import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';

class GetPropertiesParams extends Equatable {
  final int page;
  final int limit;

  const GetPropertiesParams({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class GetProperties implements UseCase<List<Property>, GetPropertiesParams> {
  final PropertyRepository repository;

  GetProperties(this.repository);

  @override
  Future<Either<Failure, List<Property>>> call(GetPropertiesParams params) {
    return repository.getProperties(page: params.page, limit: params.limit);
  }
}
