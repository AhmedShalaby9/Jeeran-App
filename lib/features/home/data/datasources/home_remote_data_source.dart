import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/city_model.dart';
import '../models/post_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<PostModel>> getPosts();
  Future<List<CityModel>> getCities();
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
  Future<List<CityModel>> getCities() async {
    try {
      final response = await apiClient.get(ApiEndpoints.cities);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(CityModel.fromJson)
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
