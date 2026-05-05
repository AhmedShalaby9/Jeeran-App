import '../../../plans/data/models/plan_model.dart';
import '../../domain/entities/user_subscription.dart';

class UserSubscriptionModel extends UserSubscription {
  const UserSubscriptionModel({
    required super.id,
    required super.userId,
    required super.packageId,
    required super.startDate,
    required super.endDate,
    required super.status,
    required super.package,
    required super.remainingListings,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      packageId: json['package_id'] as int,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      package: PlanModel.fromJson(json['package'] as Map<String, dynamic>),
      remainingListings: json['remaining_listings'] as int? ?? 0,
    );
  }
}
