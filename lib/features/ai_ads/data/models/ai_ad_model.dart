import '../../domain/entities/ai_ad.dart';

class AiAdModel extends AiAd {
  const AiAdModel({
    required super.id,
    required super.userId,
    super.parentId,
    super.trialNumber,
    required super.caption,
    required super.sourceImages,
    required super.status,
    required super.paymentStatus,
    super.resultUrl,
    super.errorMessage,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AiAdModel.fromJson(Map<String, dynamic> json) {
    return AiAdModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      parentId: json['parent_id'] as int?,
      trialNumber: json['trial_number'] as int?,
      caption: json['caption'] as String? ?? '',
      sourceImages: (json['source_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      resultUrl: json['result_url'] as String?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
