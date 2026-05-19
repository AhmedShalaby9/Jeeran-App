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
    super.remainingFeatured = 0,
    super.availableFeatured = 0,
    super.consumedFeatured = 0,
    super.paymentUrl,
    super.paymentOrderId,
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
      remainingFeatured: json['remaining_featured'] as int? ?? 0,
      availableFeatured: json['available_featured'] as int? ?? 0,
      consumedFeatured: json['consumed_featured'] as int? ?? 0,
      paymentUrl: json['payment_url'] as String?,
      paymentOrderId: json['payment_order_id'] as String?,
    );
  }
}
