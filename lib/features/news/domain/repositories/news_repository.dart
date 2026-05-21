import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/news.dart';

abstract class NewsRepository {
  Future<Either<Failure, List<News>>> getNews();
  Future<Either<Failure, void>> createNews(Map<String, dynamic> body);
  Future<Either<Failure, void>> updateNews(int id, Map<String, dynamic> body);
  Future<Either<Failure, void>> deleteNews(int id);
}
