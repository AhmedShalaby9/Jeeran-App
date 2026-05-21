import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/news_model.dart';

abstract class NewsRemoteDataSource {
  Future<List<NewsModel>> getNews();
  Future<void> createNews(Map<String, dynamic> body);
  Future<void> updateNews(int id, Map<String, dynamic> body);
  Future<void> deleteNews(int id);
}

class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  final ApiClient apiClient;

  NewsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<NewsModel>> getNews() async {
    try {
      final response = await apiClient.get(ApiEndpoints.news);
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(NewsModel.fromJson)
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
  Future<void> createNews(Map<String, dynamic> body) async {
    try {
      final response = await apiClient.post(ApiEndpoints.news, data: body);
      if (response.statusCode == 200 || response.statusCode == 201) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> updateNews(int id, Map<String, dynamic> body) async {
    try {
      final response = await apiClient.put(ApiEndpoints.newsById(id), data: body);
      if (response.statusCode == 200) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }

  @override
  Future<void> deleteNews(int id) async {
    try {
      final response = await apiClient.delete(ApiEndpoints.newsById(id));
      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw ServerException();
    } on ServerException {
      rethrow;
    } catch (_) {
      throw ServerException();
    }
  }
}
