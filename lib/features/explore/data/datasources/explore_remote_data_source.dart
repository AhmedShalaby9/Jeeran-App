import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/explore_data.dart';

class ExploreRemoteDataSource {
  final ApiClient apiClient;

  ExploreRemoteDataSource({required this.apiClient});

  /// One round trip for the whole Explore screen.
  Future<ExploreData> getHome() async {
    try {
      final response = await apiClient.get(ApiEndpoints.home);
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) return ExploreData.fromJson(data);
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
