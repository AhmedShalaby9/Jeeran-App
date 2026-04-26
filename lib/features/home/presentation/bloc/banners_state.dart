import 'package:equatable/equatable.dart';
import '../../domain/entities/app_banner.dart';

abstract class BannersState extends Equatable {
  const BannersState();
  @override
  List<Object?> get props => [];
}

class BannersInitial extends BannersState {}

class BannersLoading extends BannersState {}

class BannersLoaded extends BannersState {
  final List<AppBanner> banners;
  const BannersLoaded(this.banners);
  @override
  List<Object?> get props => [banners];
}

class BannersError extends BannersState {}

