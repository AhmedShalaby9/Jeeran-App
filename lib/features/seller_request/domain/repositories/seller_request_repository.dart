import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract class SellerRequestRepository {
  Future<Either<Failure, void>> submitSellerRequest();
}
