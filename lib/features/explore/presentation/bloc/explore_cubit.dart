import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../main/presentation/main_badges.dart';
import '../../../notifications/presentation/bloc/unread_count_cubit.dart';
import '../../data/datasources/explore_remote_data_source.dart';
import '../../data/models/explore_data.dart';

enum ExploreStatus { loading, loaded, failure }

class ExploreState extends Equatable {
  final ExploreStatus status;
  final ExploreData?
  data; // kept across refreshes and failures so the feed never blanks

  const ExploreState({required this.status, this.data});

  @override
  List<Object?> get props => [status, data];
}

class ExploreCubit extends Cubit<ExploreState> {
  final ExploreRemoteDataSource dataSource;

  ExploreCubit({required this.dataSource})
    : super(const ExploreState(status: ExploreStatus.loading));

  Future<void> load() async {
    // Keep what's on screen while refreshing; only show the skeleton on first load.
    if (state.data == null) {
      emit(const ExploreState(status: ExploreStatus.loading));
    }
    try {
      final data = await dataSource.getHome();
      emit(
        ExploreState(status: ExploreStatus.loaded, data: data),
      );

      MainBadges.savedCount.value = data.savedCount;
      MainBadges.youAttention.value = data.youAttention;
      sl<UnreadCountCubit>().set(data.unreadCount);
    } catch (_) {
      emit(
        ExploreState(status: ExploreStatus.failure, data: state.data),
      );
    }
  }
}
