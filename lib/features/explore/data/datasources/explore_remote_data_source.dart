import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/explore_data.dart';

class ExploreRemoteDataSource {
  final ApiClient apiClient;

  ExploreRemoteDataSource({required this.apiClient});

  /// One round trip for the whole Explore screen. [state] narrows by area
  /// (north_coast | cairo | sharm_el_sheikh).
  Future<ExploreData> getHome({String? state}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.home,
        queryParams: {if (state != null) 'state': state},
      );
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
