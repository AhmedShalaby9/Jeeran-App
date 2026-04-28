import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../properties/data/models/property_model.dart';

abstract class FavoritesRemoteDataSource {
  Future<List<PropertyModel>> getFavorites();
  Future<void> addFavorite(int propertyId);
  Future<void> removeFavorite(int propertyId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  final ApiClient apiClient;

  FavoritesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PropertyModel>> getFavorites() async {
    try {
      final response = await apiClient.get(ApiEndpoints.favorites);
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(PropertyModel.fromJson)
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
  Future<void> addFavorite(int propertyId) async {
    try {
      final response =
          await apiClient.post(ApiEndpoints.favoriteById(propertyId));
      if (response.statusCode == 200 || response.statusCode == 201) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> removeFavorite(int propertyId) async {
    try {
      final response =
          await apiClient.delete(ApiEndpoints.favoriteById(propertyId));
      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
