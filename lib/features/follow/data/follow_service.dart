import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

enum FollowType { project, developer }

/// Follow / unfollow a compound (project) or a developer.
/// Following files it under Saved and turns on its notifications.
class FollowService {
  final ApiClient apiClient;

  FollowService({required this.apiClient});

  Map<String, dynamic> _body(FollowType type, int id) => {'entity_type': type.name, 'entity_id': id};

  Future<bool> isFollowing(FollowType type, int id) async {
    final res = await apiClient.get(
      ApiEndpoints.followCheck,
      queryParams: {'entity_type': type.name, 'entity_id': id},
    );
    return res.data['data']?['is_following'] == true;
  }

  Future<void> follow(FollowType type, int id) async {
    try {
      await apiClient.post(ApiEndpoints.follow, data: _body(type, id));
    } catch (e) {
      // 409 = already following — the end state is what we wanted
      if (!_isConflict(e)) rethrow;
    }
  }

  Future<void> unfollow(FollowType type, int id) async {
    await apiClient.post(ApiEndpoints.unfollow, data: _body(type, id));
  }

  // the API answers 409 "Already following" — surfaced as a ServerException carrying that message
  bool _isConflict(Object e) =>
      e is ServerException && (e.message ?? '').toLowerCase().contains('already');
}
