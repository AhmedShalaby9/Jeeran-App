import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  // Firebase SDK phone auth
  String? _verificationId;
  String? _autoVerifiedIdToken; // set when Android auto-verifies SMS

  // Firebase REST fallback (iOS reCAPTCHA path — kept for backward compat)
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

  // ─── Send OTP via Firebase Auth SDK (no reCAPTCHA WebView) ───────────────
  Future<void> _onSendOtp(AuthSendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    _verificationId = null;
    _autoVerifiedIdToken = null;

    final completer = Completer<AuthState>();

    fb.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: event.phone,

      // Android: SMS auto-read succeeded — sign in immediately, skip OTP screen
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        if (completer.isCompleted) return;
        try {
          final uc = await fb.FirebaseAuth.instance.signInWithCredential(credential);
          final idToken = await uc.user?.getIdToken();
          if (idToken == null) {
            completer.complete(AuthError('Auto-verification failed'));
            return;
          }
          String? fcmToken;
          try { fcmToken = await NotificationService.instance.getToken(); } catch (_) {}
          String? deviceId;
          try { deviceId = (await DeviceInfoPlugin().androidInfo).id; } catch (_) {}

          final result = await repository.firebaseVerify(
            idToken,
            fcmToken: fcmToken,
            platform: 'android',
            deviceId: deviceId,
          );
          completer.complete(result.fold(
            (f) => AuthError(_mapFailure(f)),
            (user) => AuthPhoneChecked(
              user: user.isProfileComplete ? user : null,
              isProfileComplete: user.isProfileComplete,
            ),
          ));
        } catch (_) {
          if (!completer.isCompleted) completer.complete(AuthError('Auto-verification failed'));
        }
      },

      // SMS sent — show OTP input screen
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        if (!completer.isCompleted) {
          completer.complete(AuthOtpSent(phone: event.phone, isNewUser: false));
        }
      },

      verificationFailed: (fb.FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.complete(AuthError(e.message ?? 'SMS verification failed'));
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },

      timeout: const Duration(seconds: 60),
    );

    emit(await completer.future);
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> _onVerifyOtp(AuthVerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

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

    // Auto-verified path (Android SMS Retriever already completed sign-in)
    if (_autoVerifiedIdToken != null) {
      final result = await repository.firebaseVerify(
        _autoVerifiedIdToken!,
        fcmToken: fcmToken,
        platform: platform,
        deviceId: deviceId,
      );
      result.fold(
        (f) => emit(AuthError(_mapFailure(f))),
        (user) => emit(AuthPhoneChecked(
          user: user.isProfileComplete ? user : null,
          isProfileComplete: user.isProfileComplete,
        )),
      );
      return;
    }

    // Manual OTP entry path
    if (_verificationId == null) {
      // Fallback: old Firebase REST session (iOS reCAPTCHA path)
      if (_sessionInfo == null) {
        emit(AuthError('Session expired. Please request a new code.'));
        return;
      }
      final result = await repository.verifyOtpRest(
        _sessionInfo!,
        event.otp,
        fcmToken: fcmToken,
        platform: platform,
        deviceId: deviceId,
      );
      result.fold(
        (f) => emit(AuthError(_mapFailure(f))),
        (user) => emit(AuthPhoneChecked(
          user: user.isProfileComplete ? user : null,
          isProfileComplete: user.isProfileComplete,
        )),
      );
      return;
    }

    // Firebase SDK credential verify
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: event.otp,
      );
      final uc = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await uc.user?.getIdToken();
      if (idToken == null) {
        emit(AuthError('Authentication failed'));
        return;
      }
      final result = await repository.firebaseVerify(
        idToken,
        fcmToken: fcmToken,
        platform: platform,
        deviceId: deviceId,
      );
      result.fold(
        (f) => emit(AuthError(_mapFailure(f))),
        (user) => emit(AuthPhoneChecked(
          user: user.isProfileComplete ? user : null,
          isProfileComplete: user.isProfileComplete,
        )),
      );
    } on fb.FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Invalid verification code'));
    } catch (_) {
      emit(AuthError('Verification failed. Please try again.'));
    }
  }

  // ─── iOS reCAPTCHA REST path (kept for backward compat) ──────────────────
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
