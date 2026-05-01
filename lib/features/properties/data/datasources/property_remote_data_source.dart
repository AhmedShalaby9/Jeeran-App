import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/property_filter_params.dart';
import '../models/property_model.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties(PropertyFilterParams params);
  Future<List<PropertyModel>> getMyProperties(PropertyFilterParams params);
  Future<List<PropertyModel>> getSimilarProperties(int propertyId, {int page = 1, int limit = 20});
  Future<String> uploadImage(String filePath);
  Future<void> createProperty(Map<String, dynamic> data);
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

  @override
  Future<String> uploadImage(String filePath) async {
    try {
      final response = await apiClient.postMultipart(
        ApiEndpoints.uploadSingle,
        filePath: filePath,
        queryParams: {'folder': 'properties'},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        String? url;
        if (body is Map<String, dynamic>) {
          final data = body['data'];
          if (data is String) {
            url = data;
          } else if (data is Map<String, dynamic>) {
            url = data['url'] as String?;
          } else {
            url = body['url'] as String?;
          }
        }
        if (url != null) return url;
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> createProperty(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.properties,
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
