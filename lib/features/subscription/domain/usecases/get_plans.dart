import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/plan.dart';
import '../repositories/plan_repository.dart';

class GetPlans implements UseCase<List<Plan>, NoParams> {
  final PlanRepository repository;

  const GetPlans(this.repository);

  @override
  Future<Either<Failure, List<Plan>>> call(NoParams params) => repository.getPlans();
}
