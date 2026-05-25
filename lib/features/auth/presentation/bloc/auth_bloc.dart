import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  String? _sessionInfo;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLogin);
    on<AuthSendOtpEvent>(_onSendOtp);
    on<AuthSendOtpRestEvent>(_onSendOtpRest);
    on<AuthVerifyOtpEvent>(_onVerifyOtp);
    on<AuthCompleteProfileEvent>(_onCompleteProfile);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthGetMeEvent>(_onGetMe);
    on<AuthUpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    String? fcmToken;
    try {
      fcmToken = await NotificationService.instance.getToken();
      print('[FCM login] fcmToken at login = $fcmToken');
    } catch (e) {
      print('[FCM login] getToken FAILED: $e');
    }


    final platform = Platform.isAndroid ? 'android' : 'ios';
    String? deviceId;
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        deviceId = (await info.androidInfo).id;
      } else {
        deviceId = (await info.iosInfo).identifierForVendor;
      }
    } catch (_) {}

    final result = await repository.login(event.phone, fcmToken: fcmToken, platform: platform, deviceId: deviceId);
    result.fold((failure) => emit(AuthError(_mapFailure(failure))), (user) {
      emit(
        AuthPhoneChecked(
          user: user.isProfileComplete ? user : null,
          isProfileComplete: user.isProfileComplete,
        ),
      );
    });
  }

  Future<void> _onSendOtp(AuthSendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthRecaptchaRequired(event.phone));
  }

  Future<void> _onSendOtpRest(AuthSendOtpRestEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.sendOtpRest(event.phone, event.recaptchaToken);
    result.fold(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (sessionInfo) {
        _sessionInfo = sessionInfo;
        emit(AuthOtpSent(phone: event.phone, isNewUser: false));
      },
    );
  }

  Future<void> _onVerifyOtp(AuthVerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    if (_sessionInfo == null) {
      emit(AuthError('Session expired. Please request a new code.'));
      return;
    }
    String? fcmToken;
    try { fcmToken = await NotificationService.instance.getToken(); } catch (_) {}
    final platform = Platform.isAndroid ? 'android' : 'ios';
    String? deviceId;
    try {
      final info = DeviceInfoPlugin();
      deviceId = Platform.isAndroid
          ? (await info.androidInfo).id
          : (await info.iosInfo).identifierForVendor;
    } catch (_) {}
    final result = await repository.verifyOtpRest(
      _sessionInfo!,
      event.otp,
      fcmToken: fcmToken,
      platform: platform,
      deviceId: deviceId,
    );
    result.fold(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (user) => emit(AuthPhoneChecked(
        user: user.isProfileComplete ? user : null,
        isProfileComplete: user.isProfileComplete,
      )),
    );
  }

  Future<void> _onCompleteProfile(
    AuthCompleteProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.completeProfile(event.params);
    result.fold(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (user) {
        if (event.isStep1) {
          emit(AuthProfileStep1Completed(user));
        } else {
          emit(AuthProfileCompleted(user));
        }
      },
    );
  }

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthInitial());
  }

  Future<void> _onGetMe(AuthGetMeEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.getMe();
    result.fold(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (user) => emit(AuthMeLoaded(user)),
    );
  }

  Future<void> _onUpdateProfile(AuthUpdateProfileEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.completeProfile(event.params);
    result.fold(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (user) => emit(AuthProfileUpdated(user)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure _ => AppStrings.networkError,
    ServerFailure f => f.message ?? AppStrings.serverError,
    _ => AppStrings.unexpectedError,
  };
}
