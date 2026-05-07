import '../../../plans/data/models/plan_model.dart';
import '../../domain/entities/user_subscription.dart';

class UserSubscriptionModel extends UserSubscription {
  const UserSubscriptionModel({
    required super.id,
    required super.userId,
    required super.packageId,
    super.startDate,
    super.endDate,
    required super.status,
    required super.package,
    required super.remainingListings,
    required super.availableListings,
    required super.consumedListings,
    super.isPaid,
    super.paymentProofUrl,
    super.reviewedBy,
    super.reviewedAt,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final availableListings = json['available_listings'] as int? ?? 0;
    final consumedListings = json['consumed_listings'] as int? ?? 0;
    return UserSubscriptionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      packageId: json['package_id'] as int,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      status: json['status'] as String? ?? '',
      package: PlanModel.fromJson(json['package'] as Map<String, dynamic>),
      remainingListings: json['remaining_listings'] as int? ?? 0,
      availableListings: availableListings,
      consumedListings: consumedListings,
      isPaid: json['is_paid'] as bool? ?? false,
      paymentProofUrl: json['payment_proof_url'] as String?,
      reviewedBy: json['reviewed_by'] as int?,
      reviewedAt: json['reviewed_at'] as String?,
    );
  }
}
