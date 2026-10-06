import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/saved_models.dart';

class SavedRemoteDataSource {
  final ApiClient apiClient;

  SavedRemoteDataSource({required this.apiClient});

  Future<List<Map<String, dynamic>>> _list(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await apiClient.get(path, queryParams: query);
      if (res.statusCode == 200) {
        final data = res.data['data'];
        if (data is List) return data.whereType<Map<String, dynamic>>().toList();
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  Future<SavedCounts> counts() async {
    try {
      final res = await apiClient.get(ApiEndpoints.savedCounts);
      final data = res.data['data'];
      if (res.statusCode == 200 && data is Map<String, dynamic>) return SavedCounts.fromJson(data);
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  // limit=100 — a saved list this long is already past what anyone scrolls
  Future<List<SavedListing>> listings() async =>
      (await _list(ApiEndpoints.favorites, query: {'limit': 100})).map(SavedListing.fromJson).toList();

  Future<List<SavedCompound>> compounds() async =>
      (await _list(ApiEndpoints.savedCompounds)).map(SavedCompound.fromJson).toList();

  Future<List<SavedDeveloper>> developers() async =>
      (await _list(ApiEndpoints.savedDevelopers)).map(SavedDeveloper.fromJson).toList();

  Future<void> saveListing(int propertyId) async {
    try {
      await apiClient.post('${ApiEndpoints.favorites}/$propertyId');
    } on ServerException catch (e) {
      if (!(e.message ?? '').toLowerCase().contains('already')) rethrow;
    }
  }

  Future<void> unsaveListing(int propertyId) async {
    await apiClient.delete('${ApiEndpoints.favorites}/$propertyId');
  }
}
