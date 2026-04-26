import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_banner.dart';
import '../repositories/home_repository.dart';

class GetBanners implements UseCase<List<AppBanner>, NoParams> {
  final HomeRepository repository;
  const GetBanners(this.repository);

  @override
  Future<Either<Failure, List<AppBanner>>> call(NoParams params) =>
      repository.getBanners();
}
