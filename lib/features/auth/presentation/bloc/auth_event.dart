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

class AuthSendOtpEvent extends AuthEvent {
  final String phone;
  const AuthSendOtpEvent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class AuthVerifyOtpEvent extends AuthEvent {
  final String phone;
  final String otp;
  const AuthVerifyOtpEvent({required this.phone, required this.otp});
  @override
  List<Object?> get props => [phone, otp];
}


class AuthSendOtpRestEvent extends AuthEvent {
  final String phone;
  final String recaptchaToken;
  const AuthSendOtpRestEvent({required this.phone, required this.recaptchaToken});
  @override
  List<Object?> get props => [phone, recaptchaToken];
}

class AuthSocialLoginEvent extends AuthEvent {
  final String provider;
  final String idToken;
  final String? name;
  const AuthSocialLoginEvent({required this.provider, required this.idToken, this.name});
  @override
  List<Object?> get props => [provider, idToken, name];
}

class AuthCompleteProfileEvent extends AuthEvent {
  final CompleteProfileParams params;
  final bool isStep1;
  const AuthCompleteProfileEvent(this.params, {this.isStep1 = false});
  @override
  List<Object?> get props => [params, isStep1];
}

class AuthSendProfileOtpEvent extends AuthEvent {
  final String phone;
  final String recaptchaToken;
  const AuthSendProfileOtpEvent(this.phone, this.recaptchaToken);
  @override
  List<Object?> get props => [phone, recaptchaToken];
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
