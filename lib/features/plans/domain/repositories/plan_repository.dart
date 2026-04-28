import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/plan.dart';

abstract class PlanRepository {
  Future<Either<Failure, List<Plan>>> getPlans();
}
