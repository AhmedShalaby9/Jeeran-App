import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_subscription.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, void>> createSubscription({required int packageId});
  Future<Either<Failure, UserSubscription>> getMySubscription();
  Future<Either<Failure, void>> upgradeSubscription({required int packageId});
}
