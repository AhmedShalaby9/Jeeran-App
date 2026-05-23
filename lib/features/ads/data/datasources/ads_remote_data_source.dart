import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ad_model.dart';

abstract class AdsRemoteDataSource {
  Future<List<AdModel>> getAds();
  Future<AdModel> getAdById(int id);
}

class AdsRemoteDataSourceImpl implements AdsRemoteDataSource {
  final ApiClient apiClient;
  AdsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AdModel>> getAds() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.ads,
        queryParams: {'active': 'true'},
      );
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(AdModel.fromJson)
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
  Future<AdModel> getAdById(int id) async {
    try {
      final response = await apiClient.get(ApiEndpoints.adById(id));
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        return AdModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
