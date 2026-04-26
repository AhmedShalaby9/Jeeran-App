import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_banner.dart';
import '../entities/post.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<Post>>> getPosts();
  Future<Either<Failure, List<AppBanner>>> getBanners();
}
