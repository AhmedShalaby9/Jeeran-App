import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ad.dart';

abstract class AdsRepository {
  Future<Either<Failure, List<Ad>>> getAds();
  Future<Either<Failure, Ad>> getAdById(int id);
}
