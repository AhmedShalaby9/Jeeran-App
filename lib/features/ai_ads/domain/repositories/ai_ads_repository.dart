import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ai_ad.dart';

abstract class AiAdsRepository {
  /// Returns the payment URL for the newly created ad record.
  Future<Either<Failure, Map<String, dynamic>>> generate({
    required String caption,
    required List<String> sourceImages,
    required String language,
    bool isAdmin = false,
  });

  /// List the authenticated user's original (paid) ads.
  Future<Either<Failure, List<AiAd>>> listAds({int page = 1, int limit = 20});

  /// Get a single ad by id.
  Future<Either<Failure, AiAd>> getAd(int id);

  /// Delete an ad.
  Future<Either<Failure, void>> deleteAd(int id);

  /// Create a free trial re-generation for an original ad.
  Future<Either<Failure, AiAd>> createTrial({
    required int parentId,
    required String caption,
  });

  /// List all trials for an original ad.
  Future<Either<Failure, List<AiAd>>> listTrials(int parentId);

  /// Ask the backend to verify payment with Kashier and update status if paid.
  Future<Either<Failure, AiAd>> checkPayment(int id);
}
