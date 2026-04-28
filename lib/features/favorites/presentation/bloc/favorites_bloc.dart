import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/repositories/favorites_repository.dart';

// Events
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

class FetchFavoritesEvent extends FavoritesEvent {
  const FetchFavoritesEvent();
}

class AddFavoriteEvent extends FavoritesEvent {
  final int propertyId;
  const AddFavoriteEvent(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}

class RemoveFavoriteEvent extends FavoritesEvent {
  final int propertyId;
  const RemoveFavoriteEvent(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<Property> properties;
  const FavoritesLoaded(this.properties);
  @override
  List<Object?> get props => [properties];
}

class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository repository;

  /// In-memory set of favorited property IDs — survives navigation across
  /// the app lifecycle without relying on server-returned `is_favorited`.
  final Set<int> _favoritedIds = {};

  FavoritesBloc({required this.repository}) : super(FavoritesInitial()) {
    on<FetchFavoritesEvent>(_onFetch);
    on<AddFavoriteEvent>(_onAdd);
    on<RemoveFavoriteEvent>(_onRemove);
  }

  /// Whether a given property is currently favorited.
  /// Combines the server-seeded value (from [isFavoritedByProperty]) with
  /// any in-session add/remove actions.
  bool isFavorited(int propertyId) => _favoritedIds.contains(propertyId);

  Future<void> _onFetch(
    FetchFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    final result = await repository.getFavorites();
    result.fold(
      (failure) => emit(const FavoritesError('Failed to load favorites')),
      (properties) {
        // Seed the in-memory set from the server response
        _favoritedIds
          ..clear()
          ..addAll(properties.map((p) => p.id));
        emit(FavoritesLoaded(properties));
      },
    );
  }

  Future<void> _onAdd(
    AddFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    _favoritedIds.add(event.propertyId);
    await repository.addFavorite(event.propertyId);
  }

  Future<void> _onRemove(
    RemoveFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    _favoritedIds.remove(event.propertyId);
    await repository.removeFavorite(event.propertyId);
    if (state is FavoritesLoaded) {
      final current = (state as FavoritesLoaded).properties;
      emit(FavoritesLoaded(
        current.where((p) => p.id != event.propertyId).toList(),
      ));
    }
  }
}
