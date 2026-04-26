import '../../../../core/error/exceptions.dart';
import '../models/post_model.dart';

abstract class HomeLocalDataSource {
  Future<List<PostModel>> getCachedPosts();
  Future<void> cachePosts(List<PostModel> posts);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  List<PostModel>? _cachedPosts;

  @override
  Future<List<PostModel>> getCachedPosts() async {
    if (_cachedPosts != null) return _cachedPosts!;
    throw CacheException();
  }

  @override
  Future<void> cachePosts(List<PostModel> posts) async {
    _cachedPosts = posts;
  }
}
