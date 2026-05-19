import 'package:equatable/equatable.dart';

class AiAd extends Equatable {
  final int id;
  final int userId;
  final int? parentId;
  final int? trialNumber;
  final String caption;
  final List<String> sourceImages;
  final String status;        // pending | processing | done | failed
  final String paymentStatus; // unpaid | paid
  final String? resultUrl;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiAd({
    required this.id,
    required this.userId,
    this.parentId,
    this.trialNumber,
    required this.caption,
    required this.sourceImages,
    required this.status,
    required this.paymentStatus,
    this.resultUrl,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOriginal => parentId == null;
  bool get isPending => status == 'pending' || status == 'processing';
  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';
  bool get isPaid => paymentStatus == 'paid';

  @override
  List<Object?> get props => [
        id, userId, parentId, trialNumber, caption, sourceImages,
        status, paymentStatus, resultUrl, errorMessage, createdAt, updatedAt,
      ];
}
