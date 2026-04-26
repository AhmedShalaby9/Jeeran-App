import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/city.dart';
import '../repositories/home_repository.dart';

class GetCities implements UseCase<List<City>, NoParams> {
  final HomeRepository repository;
  const GetCities(this.repository);

  @override
  Future<Either<Failure, List<City>>> call(NoParams params) =>
      repository.getCities();
}
