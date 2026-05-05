import 'package:equatable/equatable.dart';

import '../../domain/repositories/auth_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginEvent extends AuthEvent {
  final String phone;
  const AuthLoginEvent(this.phone);
  @override
  List<Object?> get props => [phone];
}


class AuthCompleteProfileEvent extends AuthEvent {
  final CompleteProfileParams params;
  final bool isStep1;
  const AuthCompleteProfileEvent(this.params, {this.isStep1 = false});
  @override
  List<Object?> get props => [params, isStep1];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthGetMeEvent extends AuthEvent {
  const AuthGetMeEvent();
}

class AuthUpdateProfileEvent extends AuthEvent {
  final CompleteProfileParams params;
  const AuthUpdateProfileEvent(this.params);
  @override
  List<Object?> get props => [params];
}
