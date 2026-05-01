import 'package:equatable/equatable.dart';
import '../../../plans/domain/entities/plan.dart';

class UserSubscription extends Equatable {
  final int id;
  final int userId;
  final int packageId;
  final String startDate;
  final String endDate;
  final String status;
  final Plan package;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.package,
  });

  bool get isActive => status == 'active';

  int get daysRemaining {
    final end = DateTime.tryParse(endDate);
    if (end == null) return 0;
    return end.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  @override
  List<Object?> get props => [id, userId, packageId, startDate, endDate, status, package];
}
