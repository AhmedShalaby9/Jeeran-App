import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class SellerRequestRemoteDataSource {
  Future<void> submitSellerRequest();
}

class SellerRequestRemoteDataSourceImpl implements SellerRequestRemoteDataSource {
  final ApiClient apiClient;

  SellerRequestRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<void> submitSellerRequest() async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.sellerRequests,
        data: {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
