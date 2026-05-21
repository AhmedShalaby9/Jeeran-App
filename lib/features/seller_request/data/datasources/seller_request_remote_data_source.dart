import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/seller_request_model.dart';

abstract class SellerRequestRemoteDataSource {
  Future<void> submitSellerRequest();
  Future<List<SellerRequestModel>> getSellerRequests({String? status});
  Future<void> approveSellerRequest(int id);
  Future<void> rejectSellerRequest(int id);
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

  @override
  Future<List<SellerRequestModel>> getSellerRequests({String? status}) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.sellerRequests,
        queryParams: status != null ? {'status': status} : null,
      );
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(SellerRequestModel.fromJson)
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
  Future<void> approveSellerRequest(int id) async {
    try {
      final response = await apiClient.put(ApiEndpoints.sellerRequestApprove(id));
      if (response.statusCode == 200) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> rejectSellerRequest(int id) async {
    try {
      final response = await apiClient.put(ApiEndpoints.sellerRequestReject(id));
      if (response.statusCode == 200) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
