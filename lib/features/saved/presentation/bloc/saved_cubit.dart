import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../follow/data/follow_service.dart';
import '../../../main/presentation/main_badges.dart';
import '../../data/datasources/saved_remote_data_source.dart';
import '../../data/models/saved_models.dart';

enum SavedLoad { loading, loaded, failure }

class SavedState extends Equatable {
  final SavedLoad status;
  final SavedCounts counts;
  final List<SavedListing> listings;
  final List<SavedCompound> compounds;
  final List<SavedDeveloper> developers;

  const SavedState({
    this.status = SavedLoad.loading,
    this.counts = const SavedCounts(),
    this.listings = const [],
    this.compounds = const [],
    this.developers = const [],
  });

  SavedState copyWith({
    SavedLoad? status,
    SavedCounts? counts,
    List<SavedListing>? listings,
    List<SavedCompound>? compounds,
    List<SavedDeveloper>? developers,
  }) => SavedState(
    status: status ?? this.status,
    counts: counts ?? this.counts,
    listings: listings ?? this.listings,
    compounds: compounds ?? this.compounds,
    developers: developers ?? this.developers,
  );

  @override
  List<Object?> get props => [status, counts, listings, compounds, developers];
}

class SavedCubit extends Cubit<SavedState> {
  final SavedRemoteDataSource dataSource;
  final FollowService followService;

  SavedCubit({required this.dataSource, required this.followService}) : super(const SavedState());

  bool _hasData = false;

  /// Loads all three tabs at once so the counts and the summary lines are right
  /// the moment the screen shows. Keeps what is on screen while refreshing.
  Future<void> load() async {
    if (!_hasData) emit(state.copyWith(status: SavedLoad.loading));
    try {
      final r = await Future.wait([
        dataSource.counts(),
        dataSource.listings(),
        dataSource.compounds(),
        dataSource.developers(),
      ]);
      _hasData = true;
      final counts = r[0] as SavedCounts;
      emit(SavedState(
        status: SavedLoad.loaded,
        counts: counts,
        listings: r[1] as List<SavedListing>,
        compounds: r[2] as List<SavedCompound>,
        developers: r[3] as List<SavedDeveloper>,
      ));
      MainBadges.savedCount.value = counts.listings;
    } catch (_) {
      emit(state.copyWith(status: _hasData ? SavedLoad.loaded : SavedLoad.failure));
    }
  }

  // ── Removing (each returns an undo closure for the snackbar) ───────────────

  /// Un-save a listing. Optimistic; rolls back if the call fails.
  Future<Future<void> Function()?> removeListing(SavedListing item) async {
    final before = state;
    final next = state.listings.where((l) => l.property.id != item.property.id).toList();
    emit(state.copyWith(listings: next, counts: state.counts.copyWith(listings: next.length)));
    MainBadges.savedCount.value = next.length;
    try {
      await dataSource.unsaveListing(item.property.id);
    } catch (_) {
      emit(before);
      MainBadges.savedCount.value = before.counts.listings;
      return null;
    }
    return () async {
      await dataSource.saveListing(item.property.id);
      await load();
    };
  }

  Future<Future<void> Function()?> unfollowCompound(SavedCompound item) async {
    final before = state;
    final next = state.compounds.where((c) => c.project.id != item.project.id).toList();
    emit(state.copyWith(compounds: next, counts: state.counts.copyWith(compounds: next.length)));
    try {
      await followService.unfollow(FollowType.project, item.project.id);
    } catch (_) {
      emit(before);
      return null;
    }
    return () async {
      await followService.follow(FollowType.project, item.project.id);
      await load();
    };
  }

  Future<Future<void> Function()?> unfollowDeveloper(SavedDeveloper item) async {
    final before = state;
    final next = state.developers.where((d) => d.id != item.id).toList();
    emit(state.copyWith(developers: next, counts: state.counts.copyWith(developers: next.length)));
    try {
      await followService.unfollow(FollowType.developer, item.id);
    } catch (_) {
      emit(before);
      return null;
    }
    return () async {
      await followService.follow(FollowType.developer, item.id);
      await load();
    };
  }
}
