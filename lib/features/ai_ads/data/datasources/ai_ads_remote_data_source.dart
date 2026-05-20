import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ai_ad_model.dart';

abstract class AiAdsRemoteDataSource {
  Future<Map<String, dynamic>> generate({
    required String caption,
    required List<String> sourceImages,
  });
  Future<List<AiAdModel>> listAds({int page = 1, int limit = 20});
  Future<AiAdModel> getAd(int id);
  Future<void> deleteAd(int id);
  Future<AiAdModel> createTrial({required int parentId, required String caption});
  Future<List<AiAdModel>> listTrials(int parentId);
  Future<AiAdModel> checkPayment(int id);
}

class AiAdsRemoteDataSourceImpl implements AiAdsRemoteDataSource {
  final ApiClient apiClient;
  AiAdsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> generate({
    required String caption,
    required List<String> sourceImages,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.aiAdsGenerate,
        data: {'caption': caption, 'source_images': sourceImages},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw ServerException(
        response.data?['message'] as String? ?? 'Failed to generate ad',
      );
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<List<AiAdModel>> listAds({int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.aiAds,
        queryParams: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(AiAdModel.fromJson)
            .toList();
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<AiAdModel> getAd(int id) async {
    try {
      final response = await apiClient.get(ApiEndpoints.aiAdById(id));
      if (response.statusCode == 200) {
        return AiAdModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> deleteAd(int id) async {
    try {
      final response = await apiClient.delete(ApiEndpoints.aiAdById(id));
      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<AiAdModel> createTrial({
    required int parentId,
    required String caption,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.aiAdTrials(parentId),
        data: {'caption': caption},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AiAdModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw ServerException(
        response.data?['message'] as String? ?? 'Failed to create trial',
      );
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<AiAdModel> checkPayment(int id) async {
    try {
      final response = await apiClient.post(ApiEndpoints.aiAdCheckPayment(id));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AiAdModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw ServerException(
        response.data?['message'] as String? ?? 'Failed to check payment',
      );
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<List<AiAdModel>> listTrials(int parentId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.aiAdTrials(parentId));
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(AiAdModel.fromJson)
            .toList();
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
