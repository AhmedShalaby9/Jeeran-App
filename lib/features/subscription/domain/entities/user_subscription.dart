import 'package:equatable/equatable.dart';
import '../../../plans/domain/entities/plan.dart';

class UserSubscription extends Equatable {
  final int id;
  final int userId;
  final int packageId;
  final String? startDate;
  final String? endDate;
  final String status;
  final Plan package;
  final int remainingListings;
  final int availableListings;
  final int consumedListings;
  final bool isPaid;
  final String? paymentProofUrl;
  final int? reviewedBy;
  final String? reviewedAt;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.packageId,
    this.startDate,
    this.endDate,
    required this.status,
    required this.package,
    required this.remainingListings,
    required this.availableListings,
    required this.consumedListings,
    this.isPaid = false,
    this.paymentProofUrl,
    this.reviewedBy,
    this.reviewedAt,
  });

  bool get isActive => status == 'active';
  bool get isPendingPayment => status == 'pending_payment';
  bool get isPendingApproval => status == 'pending_approval';

  int get daysRemaining {
    if (endDate == null) return 0;
    final end = DateTime.tryParse(endDate!);
    if (end == null) return 0;
    return end.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  @override
  List<Object?> get props => [
    id, userId, packageId, startDate, endDate, status, package,
    remainingListings, availableListings, consumedListings,
    isPaid, paymentProofUrl, reviewedBy, reviewedAt,
  ];
}
