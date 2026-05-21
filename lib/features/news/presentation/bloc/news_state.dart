import 'package:equatable/equatable.dart';
import '../../domain/entities/news.dart';

abstract class NewsState extends Equatable {
  const NewsState();
  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<News> news;
  const NewsLoaded(this.news);
  @override
  List<Object?> get props => [news];
}

class NewsError extends NewsState {
  final String message;
  const NewsError(this.message);
  @override
  List<Object?> get props => [message];
}

class NewsUploading extends NewsState {
  final int current;
  final int total;
  const NewsUploading({required this.current, required this.total});
  @override
  List<Object?> get props => [current, total];
}

class NewsActionSuccess extends NewsState {}

class NewsActionError extends NewsState {
  final String message;
  const NewsActionError(this.message);
  @override
  List<Object?> get props => [message];
}
