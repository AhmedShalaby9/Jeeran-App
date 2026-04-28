import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/plan_model.dart';

abstract class PlanRemoteDataSource {
  Future<List<PlanModel>> getPlans();
}

class PlanRemoteDataSourceImpl implements PlanRemoteDataSource {
  final ApiClient apiClient;

  PlanRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PlanModel>> getPlans() async {
    try {
      final response = await apiClient.get(ApiEndpoints.packages);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.whereType<Map<String, dynamic>>().map(PlanModel.fromJson).toList();
      }
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
