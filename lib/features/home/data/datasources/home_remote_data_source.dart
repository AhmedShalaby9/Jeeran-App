import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/banner_model.dart';
import '../models/post_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<PostModel>> getPosts();
  Future<List<BannerModel>> getBanners();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient apiClient;

  HomeRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PostModel>> getPosts() async {
    try {
      final response = await apiClient.get(ApiEndpoints.properties);
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => PostModel.fromJson(json))
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
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await apiClient.get(ApiEndpoints.banners);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(BannerModel.fromJson)
            .where((b) => b.isActive && b.imageUrl.isNotEmpty)
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
