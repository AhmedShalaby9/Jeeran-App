import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/seller_request_model.dart';

abstract class SellerRequestRepository {
  Future<Either<Failure, void>> submitSellerRequest();
  Future<Either<Failure, List<SellerRequestModel>>> getSellerRequests({String? status});
  Future<Either<Failure, void>> approveSellerRequest(int id);
  Future<Either<Failure, void>> rejectSellerRequest(int id);
}
