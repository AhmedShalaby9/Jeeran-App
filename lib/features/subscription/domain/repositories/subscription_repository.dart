import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_subscription.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, UserSubscription>> createSubscription({required int packageId});
  Future<Either<Failure, UserSubscription>> getMySubscription();
  Future<Either<Failure, UserSubscription>> upgradeSubscription({required int packageId});
  Future<Either<Failure, void>> cancelSubscription();
  Future<Either<Failure, List<UserSubscription>>> getSubscriptionHistory();
  Future<Either<Failure, UserSubscription>> submitPaymentProof({
    required int subscriptionId,
    required String filePath,
  });
}
