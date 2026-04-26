import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/city.dart';
import '../entities/post.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<Post>>> getPosts();
  Future<Either<Failure, List<City>>> getCities();
}
