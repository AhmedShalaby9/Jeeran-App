import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/property_filter_params.dart';
import '../models/property_model.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties(PropertyFilterParams params);
  Future<List<PropertyModel>> getMyProperties(PropertyFilterParams params);
  Future<List<PropertyModel>> getSimilarProperties(int propertyId, {int page = 1, int limit = 20});
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final ApiClient apiClient;

  PropertyRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PropertyModel>> getProperties(PropertyFilterParams params) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.properties,
        queryParams: params.toJson(),
      );
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
  Future<List<PropertyModel>> getMyProperties(PropertyFilterParams params) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.myProperties,
        queryParams: params.toJson(),
      );
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
  Future<List<PropertyModel>> getSimilarProperties(int propertyId, {int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.similarProperties(propertyId),
        queryParams: {'page': page.toString(), 'limit': limit.toString()},
      );
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
}
