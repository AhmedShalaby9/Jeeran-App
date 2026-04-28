import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthPhoneChecked extends AuthState {
  final User? user;
  final bool isProfileComplete;
  const AuthPhoneChecked({this.user, this.isProfileComplete = false});
  @override
  List<Object?> get props => [user, isProfileComplete];
}

class AuthProfileStep1Completed extends AuthState {
  final User user;
  const AuthProfileStep1Completed(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthProfileCompleted extends AuthState {
  final User user;
  const AuthProfileCompleted(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthMeLoaded extends AuthState {
  final User user;
  const AuthMeLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
