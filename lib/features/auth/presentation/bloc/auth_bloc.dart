import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  String? _verificationId;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLogin);
    on<AuthSendOtpEvent>(_onSendOtp);
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
    emit(AuthLoading());
    final completer = Completer<void>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: event.phone,
      verificationCompleted: (credential) async {
        await _signInWithCredential(credential, emit);
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (e) {
        emit(AuthError(e.message ?? 'Phone verification failed'));
        if (!completer.isCompleted) completer.complete();
      },
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        emit(AuthOtpSent(phone: event.phone, isNewUser: false));
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  Future<void> _onVerifyOtp(AuthVerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    if (_verificationId == null || _verificationId!.isEmpty) {
      emit(AuthError('Session expired. Please request a new code.'));
      return;
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: event.otp,
    );
    await _signInWithCredential(credential, emit);
  }

  Future<void> _signInWithCredential(
    PhoneAuthCredential credential,
    Emitter<AuthState> emit,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        emit(AuthError('Authentication failed. Please try again.'));
        return;
      }
      final idToken = await firebaseUser.getIdToken();

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

      final result = await repository.firebaseVerify(
        idToken!,
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
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Invalid verification code'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
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
