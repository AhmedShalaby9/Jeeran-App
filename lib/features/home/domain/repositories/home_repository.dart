import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/post.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<Post>>> getPosts();
}
